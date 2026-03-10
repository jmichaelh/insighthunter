import { Hono } from 'hono';
import type { Env } from '../types/env';
import type { AuthContext } from '../types/auth';
import { verifyAccessToken } from '../services/tokenService';
import { getUserById, updateUser } from '../db/queries';
import { hashPassword } from '../lib/password';
import { verifyPassword } from '../lib/password';
import { trackEvent } from '../lib/analytics';

export const meRoutes = new Hono<{ Bindings: Env }>();

// ── Auth guard (local — no service binding needed, auth IS this worker) ───────
async function getAuth(c: any): Promise<AuthContext | null> {
  const token = c.req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return null;
  return verifyAccessToken(token, c.env.JWT_SECRET);
}

// ── GET /auth/me ──────────────────────────────────────────────────────────────
meRoutes.get('/me', async c => {
  const ctx = await getAuth(c);
  if (!ctx) return c.json({ error: 'Unauthorized' }, 401);

  const user = await getUserById(c.env.DB, ctx.userId);
  if (!user) return c.json({ error: 'User not found' }, 404);

  // Never return password_hash
  return c.json({
     {
      id:        user.id,
      email:     user.email,
      name:      user.name,
      orgId:     user.orgId,
      role:      user.role,
      plan:      user.plan,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
    },
  });
});

// ── PATCH /auth/me ────────────────────────────────────────────────────────────
// Update name and/or email
meRoutes.patch('/me', async c => {
  const ctx = await getAuth(c);
  if (!ctx) return c.json({ error: 'Unauthorized' }, 401);

  const body = await c.req.json<{ name?: string; email?: string }>();

  if (!body.name && !body.email)
    return c.json({ error: 'Nothing to update' }, 400);

  if (body.email) {
    const existing = await c.env.DB.prepare(
      'SELECT id FROM users WHERE email=? AND id != ?'
    ).bind(body.email.toLowerCase(), ctx.userId).first();
    if (existing) return c.json({ error: 'Email already in use' }, 409);
  }

  await updateUser(c.env.DB, ctx.userId, {
    ...(body.name  && { name:  body.name }),
    ...(body.email && { email: body.email.toLowerCase() }),
  });

  trackEvent(c.env.ANALYTICS, 'user_updated', ctx.orgId, { userId: ctx.userId });
  return c.json({ ok: true });
});

// ── POST /auth/me/password ────────────────────────────────────────────────────
meRoutes.post('/me/password', async c => {
  const ctx = await getAuth(c);
  if (!ctx) return c.json({ error: 'Unauthorized' }, 401);

  const body = await c.req.json<{ currentPassword: string; newPassword: string }>();
  if (!body.currentPassword || !body.newPassword)
    return c.json({ error: 'currentPassword and newPassword required' }, 400);
  if (body.newPassword.length < 8)
    return c.json({ error: 'Password must be at least 8 characters' }, 400);

  const row = await c.env.DB.prepare(
    'SELECT password_hash FROM users WHERE id=?'
  ).bind(ctx.userId).first<{ password_hash: string }>();
  if (!row) return c.json({ error: 'User not found' }, 404);

  const valid = await verifyPassword(body.currentPassword, row.password_hash);
  if (!valid) return c.json({ error: 'Current password is incorrect' }, 403);

  const newHash = await hashPassword(body.newPassword);
  await c.env.DB.prepare(
    'UPDATE users SET password_hash=?, updated_at=? WHERE id=?'
  ).bind(newHash, new Date().toISOString(), ctx.userId).run();

  // Revoke all refresh tokens — forces re-login on all devices
  const list = await c.env.KV.list({ prefix: `refresh:${ctx.userId}:` });
  await Promise.all(list.keys.map(k => c.env.KV.delete(k.name)));

  trackEvent(c.env.ANALYTICS, 'password_changed', ctx.orgId, { userId: ctx.userId });
  return c.json({ ok: true, message: 'Password updated. Please log in again.' });
});

// ── DELETE /auth/me ───────────────────────────────────────────────────────────
// Soft-delete — sets is_active = 0
meRoutes.delete('/me', async c => {
  const ctx = await getAuth(c);
  if (!ctx) return c.json({ error: 'Unauthorized' }, 401);

  // Only non-owners can self-delete without org teardown
  if (ctx.role === 'owner')
    return c.json({ error: 'Org owners must delete via DELETE /auth/org to teardown the org first' }, 400);

  await c.env.DB.prepare(
    'UPDATE users SET is_active=0, updated_at=? WHERE id=?'
  ).bind(new Date().toISOString(), ctx.userId).run();

  // Revoke all tokens
  const list = await c.env.KV.list({ prefix: `refresh:${ctx.userId}:` });
  await Promise.all(list.keys.map(k => c.env.KV.delete(k.name)));

  trackEvent(c.env.ANALYTICS, 'user_deactivated', ctx.orgId, { userId: ctx.userId });
  return c.json({ ok: true });
});
