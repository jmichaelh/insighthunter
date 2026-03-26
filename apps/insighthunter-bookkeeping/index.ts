// apps/insighthunter-platform/src/index.ts
// InsightHunter Platform Worker — entry point.
//
// Responsibilities:
//  1. Route incoming tenant requests via dispatch namespace
//  2. Expose internal provisioning API for insighthunter-auth
//  3. Handle the bare bookkeeping.insighthunter.app marketing/redirect page
//
// Monorepo path: apps/insighthunter-platform
// Handles:
//   *.bookkeeping.insighthunter.app  →  tenant workers (dispatch)
//   bookkeeping.insighthunter.app    →  redirect to insighthunter.app/bookkeeping (marketing)
//   /platform/*                      →  internal management API

import { Hono } from 'hono';
import { Env } from './types/index.js';
import { routes } from './routes/index.js';
import { dispatchToTenant } from './services/dispatcher.js';

const app = new Hono<{ Bindings: Env }>();

// ─── Management API routes ────────────────────────────────────────────────────
app.route('/', routes);

// ─── Everything else — dispatch or redirect ───────────────────────────────────
app.all('*', async (c) => {
  const url = new URL(c.req.url);
  const hostname = url.hostname;

  // ── Tenant dispatch ────────────────────────────────────────────────────────
  // If the hostname is a tenant subdomain, forward to their isolated worker
  const tenantResponse = await dispatchToTenant(c.req.raw, c.env);
  if (tenantResponse) return tenantResponse;

  // ── Bare domain — bookkeeping.insighthunter.app ────────────────────────────
  // Redirect to marketing page on the main site
  if (hostname === `bookkeeping.${c.env.BASE_DOMAIN}`) {
    return c.redirect(`https://${c.env.BASE_DOMAIN}/products/bookkeeping`, 302);
  }

  return c.json({ error: 'Not found' }, 404);
});

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    return app.fetch(request, env, ctx);
  },
} satisfies ExportedHandler<Env>;
