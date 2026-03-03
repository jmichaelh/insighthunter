// apps/insighthunter-auth/src/pages/api/auth/reset-password.ts
import type { APIRoute } from 'astro';
import { verifyJWT, hashPassword, auditLog, deleteSession } from '../../../lib/auth';

export const POST: APIRoute = async ({ request, locals, clientAddress }) => {
  const env = locals.runtime.env;

  try {
    const { token, password } = await request.json() as {
      token: string; password: string;
    };

    if (!token || !password) return err('Token and password are required', 400);
    if (password.length < 8)  return err('Password must be at least 8 characters', 400);

    // Verify the reset token
    let email: string;
    try {
      const payload = await verifyJWT(token, env.VERIFY_EMAIL_JWT_SECRET);
      email = payload.email as string;
      if (!email) throw new Error('Invalid token payload');
    } catch {
      return err('Reset link is invalid or has expired. Please request a new one.', 400);
    }

    // Get user
    const user = await env.DB.prepare(
      `SELECT id FROM users WHERE email = ?`
    ).bind(email.toLowerCase()).first<{ id: string }>();

    if (!user) return err('Account not found.', 404);

    // Update password
    const passwordHash = await hashPassword(password);
    await env.DB.prepare(
      `UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?`
    ).bind(passwordHash, user.id).run();

    // Invalidate all existing sessions for this user (security: log out all devices)
    const { results: sessions } = await env.DB.prepare(
      `SELECT id FROM sessions WHERE user_id = ?`
    ).bind(user.id).all<{ id: string }>();

    await Promise.all(sessions.map(s => deleteSession(env, s.id)));

    const ip = clientAddress ?? request.headers.get('CF-Connecting-IP') ?? 'unknown';
    auditLog(env, 'password_reset_completed', user.id, ip,
      request.headers.get('user-agent') ?? '');

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (e) {
    console.error('Reset password error:', e);
    return err('An unexpected error occurred.', 500);
  }
};

const err = (message: string, status: number) =>
  new Response(JSON.stringify({ error: message }), {
    status, headers: { 'Content-Type': 'application/json' },
  });
