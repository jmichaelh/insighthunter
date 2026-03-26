// apps/insighthunter-platform/src/routes/index.ts
// Internal API routes for the platform worker.
// All management endpoints are protected by PLATFORM_SECRET —
// only insighthunter-auth and insighthunter-platform-admin can call them.

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Env, ProvisionRequest } from '../types/index.js';
import {
  provisionTenant,
  deprovisionTenant,
  updateTenantTier,
  sanitizeSlug,
} from '../services/provisioner.js';

const routes = new Hono<{ Bindings: Env }>();

// ─── CORS: only auth service and admin ───────────────────────────────────────
routes.use('/platform/*', cors({
  origin: [
    'https://auth.insighthunter.app',
    'https://admin.insighthunter.app',
  ],
  allowHeaders: ['Authorization', 'Content-Type', 'X-Platform-Secret'],
  allowMethods: ['GET', 'POST', 'PATCH', 'DELETE'],
}));

// ─── Auth middleware for platform API ────────────────────────────────────────
async function requirePlatformSecret(
  c: { req: { header: (k: string) => string | undefined }; json: (b: unknown, s?: number) => Response },
  next: () => Promise<void>
) {
  const secret = c.req.header('X-Platform-Secret');
  if (!secret) {
    return c.json({ success: false, error: 'Missing X-Platform-Secret header' }, 401);
  }
  // Constant-time compare to prevent timing attacks
  const encoder = new TextEncoder();
  const a = encoder.encode(secret);
  const b = encoder.encode((c as any).env?.PLATFORM_SECRET ?? '');
  if (a.length !== b.length) return c.json({ success: false, error: 'Unauthorized' }, 401);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i]! ^ b[i]!;
  if (diff !== 0) return c.json({ success: false, error: 'Unauthorized' }, 401);
  await next();
}

routes.use('/platform/*', requirePlatformSecret as any);

// ─── Health ───────────────────────────────────────────────────────────────────
routes.get('/health', (c) =>
  c.json({ status: 'ok', service: 'insighthunter-platform' })
);

// ══════════════════════════════════════════════════════════════════════════════
// PROVISIONING
// ══════════════════════════════════════════════════════════════════════════════

/**
 * POST /platform/provision
 * Called by insighthunter-auth immediately after a new user signs up.
 *
 * Body: ProvisionRequest
 * Response: { success, tenantId, workerUrl, customDomain }
 *
 * This is async-safe — duplicate calls for the same orgId are idempotent.
 */
routes.post('/platform/provision', async (c) => {
  let body: ProvisionRequest;
  try {
    body = await c.req.json<ProvisionRequest>();
  } catch {
    return c.json({ success: false, error: 'Invalid JSON body' }, 400);
  }

  // Validate required fields
  const required = ['orgId', 'userId', 'email', 'slug', 'tier'] as const;
  for (const field of required) {
    if (!body[field]) {
      return c.json({ success: false, error: `Missing required field: ${field}` }, 400);
    }
  }

  // Sanitize and validate slug
  const slug = sanitizeSlug(body.slug);
  if (slug.length < 3) {
    return c.json({ success: false, error: 'Slug must be at least 3 characters after sanitization' }, 400);
  }

  // Check slug uniqueness before provisioning
  const slugConflict = await c.env.PLATFORM_DB
    .prepare(`SELECT id FROM tenants WHERE slug = ? AND org_id != ? AND status != 'deleted'`)
    .bind(slug, body.orgId)
    .first();

  if (slugConflict) {
    // Auto-suffix with a short hash to resolve conflict
    const suffix = body.orgId.slice(0, 6);
    body.slug = `${slug}-${suffix}`;
    console.log(`Slug conflict for '${slug}' — using '${body.slug}'`);
  } else {
    body.slug = slug;
  }

  console.log(`Provisioning tenant: orgId=${body.orgId} slug=${body.slug} tier=${body.tier}`);

  const result = await provisionTenant(c.env, body);

  if (!result.success) {
    return c.json(result, 500);
  }

  return c.json(result, 201);
});

/**
 * POST /platform/provision/secrets
 * Called by insighthunter-auth BEFORE /provision to stage per-tenant secrets.
 * Secrets are stored in platform KV temporarily, consumed during worker upload,
 * then deleted. Never stored in D1 or logs.
 */
routes.post('/platform/provision/secrets', async (c) => {
  const body = await c.req.json<{
    orgId: string;
    authJwtSecret: string;
    openAiApiKey: string;
    qbClientId: string;
    qbClientSecret: string;
    stripeWebhookSecret: string;
  }>();

  if (!body.orgId) return c.json({ success: false, error: 'Missing orgId' }, 400);

  // Store with 15-minute TTL — must be consumed by /provision within that window
  await c.env.PLATFORM_KV.put(
    `tenant_secrets:${body.orgId}`,
    JSON.stringify({
      authJwtSecret: body.authJwtSecret,
      openAiApiKey: body.openAiApiKey,
      qbClientId: body.qbClientId,
      qbClientSecret: body.qbClientSecret,
      stripeWebhookSecret: body.stripeWebhookSecret,
    }),
    { expirationTtl: 900 } // 15 minutes
  );

  return c.json({ success: true });
});

/**
 * DELETE /platform/deprovision/:orgId
 * Called by insighthunter-auth on account deletion or GDPR erasure request.
 * Destroys all CF resources and marks tenant as deleted.
 */
routes.delete('/platform/deprovision/:orgId', async (c) => {
  const orgId = c.req.param('orgId');
  console.log(`Deprovisioning tenant: orgId=${orgId}`);

  const result = await deprovisionTenant(c.env, orgId);
  return c.json(result, result.success ? 200 : 500);
});

/**
 * PATCH /platform/tier/:orgId
 * Called by insighthunter-auth when a subscription upgrade/downgrade occurs.
 * Re-uploads the tenant worker with the updated TIER binding.
 */
routes.patch('/platform/tier/:orgId', async (c) => {
  const orgId = c.req.param('orgId');
  const { tier } = await c.req.json<{ tier: 'free' | 'standard' | 'pro' }>();

  if (!['free', 'standard', 'pro'].includes(tier)) {
    return c.json({ success: false, error: 'Invalid tier' }, 400);
  }

  try {
    await updateTenantTier(c.env, orgId, tier);
    return c.json({ success: true });
  } catch (err) {
    return c.json({ success: false, error: err instanceof Error ? err.message : 'Tier update failed' }, 500);
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// STATUS & ADMIN
// ══════════════════════════════════════════════════════════════════════════════

/**
 * GET /platform/tenant/:orgId
 * Returns the provisioning status and resource IDs for a tenant.
 */
routes.get('/platform/tenant/:orgId', async (c) => {
  const orgId = c.req.param('orgId');
  const tenant = await c.env.PLATFORM_DB
    .prepare('SELECT * FROM tenants WHERE org_id = ?')
    .bind(orgId)
    .first();

  if (!tenant) return c.json({ success: false, error: 'Tenant not found' }, 404);
  return c.json({ success: true, data: tenant });
});

/**
 * GET /platform/tenants
 * Admin: list all tenants with pagination.
 */
routes.get('/platform/tenants', async (c) => {
  const page = parseInt(c.req.query('page') ?? '1');
  const pageSize = 50;
  const status = c.req.query('status');
  const offset = (page - 1) * pageSize;

  let query = 'SELECT id, org_id, slug, tier, status, custom_domain, provisioned_at FROM tenants';
  const params: unknown[] = [];
  if (status) { query += ' WHERE status = ?'; params.push(status); }
  query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
  params.push(pageSize, offset);

  const result = await c.env.PLATFORM_DB.prepare(query).bind(...params).all();
  const count = await c.env.PLATFORM_DB
    .prepare(`SELECT COUNT(*) as cnt FROM tenants${status ? ' WHERE status = ?' : ''}`)
    .bind(...(status ? [status] : []))
    .first<{ cnt: number }>();

  return c.json({
    success: true,
    data: result.results,
    pagination: {
      page, pageSize,
      total: count?.cnt ?? 0,
      totalPages: Math.ceil((count?.cnt ?? 0) / pageSize),
    },
  });
});

/**
 * POST /platform/tenant/:orgId/suspend
 * Suspend a tenant (non-payment). Marks worker as suspended — requests return 402.
 */
routes.post('/platform/tenant/:orgId/suspend', async (c) => {
  const orgId = c.req.param('orgId');
  await c.env.PLATFORM_DB.prepare(
    `UPDATE tenants SET status = 'suspended', suspended_at = datetime('now'), updated_at = datetime('now') WHERE org_id = ?`
  ).bind(orgId).run();

  // Invalidate cache
  await c.env.PLATFORM_KV.delete(`tenant:${orgId}`);

  return c.json({ success: true });
});

/**
 * POST /platform/tenant/:orgId/unsuspend
 */
routes.post('/platform/tenant/:orgId/unsuspend', async (c) => {
  const orgId = c.req.param('orgId');
  await c.env.PLATFORM_DB.prepare(
    `UPDATE tenants SET status = 'active', suspended_at = NULL, updated_at = datetime('now') WHERE org_id = ?`
  ).bind(orgId).run();

  await c.env.PLATFORM_KV.delete(`tenant:${orgId}`);
  return c.json({ success: true });
});

export { routes };
