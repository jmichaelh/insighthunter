// apps/insighthunter-platform/src/services/dispatcher.ts
// Routes incoming HTTP requests to the correct per-tenant worker
// using the Workers for Platforms dispatch namespace.
//
// Routing logic:
//   acme-consulting.bookkeeping.insighthunter.app  →  worker: ih-bk-acme-consulting
//   bookkeeping.insighthunter.app                  →  marketing/login page (insighthunter-bookkeeping-web)
//
// The dispatch namespace handles the actual call forwarding —
// we just resolve the right worker name from the hostname.

import { Env } from '../types/index.js';

interface TenantLookup {
  workerName: string;
  domain: string;
  slug: string;
}

/**
 * Resolve the worker name for a given hostname.
 *
 * Lookup order:
 *  1. KV cache (24h TTL — fastest path)
 *  2. Platform D1 (authoritative)
 *  3. 404 if not found
 */
async function resolveWorker(
  env: Env,
  hostname: string
): Promise<TenantLookup | null> {
  // Extract slug from hostname
  // acme-consulting.bookkeeping.insighthunter.app → acme-consulting
  const baseDomain = `bookkeeping.${env.BASE_DOMAIN}`;
  if (!hostname.endsWith(baseDomain)) return null;

  const slug = hostname.replace(`.${baseDomain}`, '');
  if (!slug || slug === hostname) return null; // Bare bookkeeping.insighthunter.app

  // Check KV cache first
  const orgLookupKey = `slug:${slug}`;
  const cached = await env.PLATFORM_KV.get<{ orgId: string }>(orgLookupKey, 'json');

  if (cached) {
    const tenantCached = await env.PLATFORM_KV.get<TenantLookup>(
      `tenant:${cached.orgId}`, 'json'
    );
    if (tenantCached) return tenantCached;
  }

  // Fall back to D1
  const tenant = await env.PLATFORM_DB
    .prepare(`
      SELECT worker_name, custom_domain, slug, org_id
      FROM tenants
      WHERE slug = ? AND status = 'active'
    `)
    .bind(slug)
    .first<{ worker_name: string; custom_domain: string; slug: string; org_id: string }>();

  if (!tenant) return null;

  const lookup: TenantLookup = {
    workerName: tenant.worker_name,
    domain: tenant.custom_domain,
    slug: tenant.slug,
  };

  // Warm both caches
  await Promise.all([
    env.PLATFORM_KV.put(`tenant:${tenant.org_id}`, JSON.stringify(lookup), { expirationTtl: 86400 }),
    env.PLATFORM_KV.put(orgLookupKey, JSON.stringify({ orgId: tenant.org_id }), { expirationTtl: 86400 }),
  ]);

  return lookup;
}

/**
 * Dispatch an incoming request to the correct tenant worker.
 * Returns null if this request should fall through to the default handler.
 */
export async function dispatchToTenant(
  request: Request,
  env: Env
): Promise<Response | null> {
  const url = new URL(request.url);
  const hostname = url.hostname;

  const tenant = await resolveWorker(env, hostname);
  if (!tenant) return null;

  try {
    // Get a handle to the specific user worker in the dispatch namespace
    const tenantWorker = env.BOOKKEEPING_DISPATCH.get(tenant.workerName);

    // Forward the request as-is to the tenant worker
    // The tenant worker has its own D1/KV/R2 bindings and sees it as a normal request
    const response = await tenantWorker.fetch(request);
    return response;

  } catch (err) {
    console.error(`Dispatch error for worker ${tenant.workerName}:`, err);

    // Return a graceful error rather than an unhandled exception
    return new Response(
      JSON.stringify({
        error: 'Service temporarily unavailable',
        tenant: tenant.slug,
      }),
      {
        status: 503,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}
