// apps/insighthunter-platform/src/services/provisioner.ts
// Orchestrates full per-tenant infrastructure provisioning.
// Called once at signup. Implements saga-style rollback on partial failure.

import {
  Env,
  TenantRecord,
  ProvisionRequest,
  ProvisionResult,
} from '../types/index.js';
import {
  createD1Database,
  migrateD1Database,
  createKVNamespace,
  createR2Bucket,
  uploadTenantWorker,
  createTenantDNSRecord,
  attachCustomDomain,
  deleteTenantWorker,
  deleteD1Database,
  deleteKVNamespace,
  deleteR2Bucket,
  deleteDNSRecord,
} from './cloudflare-api.js';

// ─── Resource name helpers ────────────────────────────────────────────────────

/**
 * Sanitize user-supplied org slug to a safe resource-name string.
 * Cloudflare resource names must be lowercase alphanumeric + hyphens, max 63 chars.
 */
export function sanitizeSlug(raw: string): string {
  return raw
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 40);
}

function workerName(slug: string): string {
  return `ih-bk-${slug}`;
}

function d1Name(slug: string): string {
  return `ih-bk-db-${slug}`;
}

function kvName(slug: string): string {
  return `ih-bk-kv-${slug}`;
}

function r2Name(slug: string): string {
  return `ih-bk-files-${slug}`;
}

function tenantDomain(slug: string, baseDomain: string): string {
  return `${slug}.bookkeeping.${baseDomain}`;
}

// ─── Provisioning lock ────────────────────────────────────────────────────────

/**
 * Acquire an idempotency lock in KV so duplicate signup webhooks
 * don't double-provision. TTL = 10 minutes.
 */
async function acquireLock(env: Env, orgId: string): Promise<boolean> {
  const key = `provision_lock:${orgId}`;
  const existing = await env.PLATFORM_KV.get(key);
  if (existing) return false; // Already in progress
  await env.PLATFORM_KV.put(key, '1', { expirationTtl: 600 });
  return true;
}

async function releaseLock(env: Env, orgId: string): Promise<void> {
  await env.PLATFORM_KV.delete(`provision_lock:${orgId}`);
}

// ─── Schema loader ────────────────────────────────────────────────────────────

/**
 * Load the bookkeeping schema.sql from R2 (uploaded at build time by CI/CD).
 * The deploy pipeline runs: `wrangler r2 object put platform-assets/schema.sql --file schema.sql`
 */
async function loadSchema(env: Env): Promise<string> {
  const obj = await env.PLATFORM_ASSETS.get('schema.sql');
  if (!obj) throw new Error('schema.sql not found in PLATFORM_ASSETS bucket');
  return obj.text();
}

/**
 * Load the compiled tenant worker bundle from R2.
 * The deploy pipeline runs: `wrangler r2 object put platform-assets/worker-bundle.js --file dist/index.js`
 */
async function loadWorkerBundle(env: Env): Promise<ArrayBuffer> {
  const obj = await env.PLATFORM_ASSETS.get('worker-bundle.js');
  if (!obj) throw new Error('worker-bundle.js not found in PLATFORM_ASSETS bucket');
  return obj.arrayBuffer();
}

// ─── Rollback handler ─────────────────────────────────────────────────────────

interface ProvisionedResources {
  workerName?: string;
  d1DatabaseId?: string;
  kvNamespaceId?: string;
  r2BucketName?: string;
  dnsRecordId?: string;
}

/**
 * Rollback any resources that were successfully created before a failure.
 * Best-effort — logs errors but doesn't re-throw.
 */
async function rollback(env: Env, resources: ProvisionedResources): Promise<void> {
  console.warn('Provisioning failed — rolling back resources:', resources);

  const tasks: Promise<void>[] = [];

  if (resources.workerName) {
    tasks.push(
      deleteTenantWorker(env, resources.workerName)
        .catch((e) => console.error('Rollback: worker delete failed', e))
    );
  }
  if (resources.dnsRecordId) {
    tasks.push(
      deleteDNSRecord(env, resources.dnsRecordId)
        .catch((e) => console.error('Rollback: DNS delete failed', e))
    );
  }
  if (resources.d1DatabaseId) {
    tasks.push(
      deleteD1Database(env, resources.d1DatabaseId)
        .catch((e) => console.error('Rollback: D1 delete failed', e))
    );
  }
  if (resources.kvNamespaceId) {
    tasks.push(
      deleteKVNamespace(env, resources.kvNamespaceId)
        .catch((e) => console.error('Rollback: KV delete failed', e))
    );
  }
  if (resources.r2BucketName) {
    tasks.push(
      deleteR2Bucket(env, resources.r2BucketName)
        .catch((e) => console.error('Rollback: R2 delete failed', e))
    );
  }

  await Promise.allSettled(tasks);
}

// ─── Main provisioner ─────────────────────────────────────────────────────────

/**
 * Provision a complete isolated tenant environment.
 *
 * Sequence:
 *  1. Acquire idempotency lock
 *  2. Check for existing tenant (idempotent re-run)
 *  3. Create D1 database + run schema migrations
 *  4. Create KV namespace
 *  5. Create R2 bucket
 *  6. Upload tenant worker to dispatch namespace with resource bindings
 *  7. Create DNS CNAME record
 *  8. Attach custom domain to worker
 *  9. Write tenant record to platform D1
 * 10. Release lock
 *
 * On any failure: rollback already-created resources and mark tenant as failed.
 */
export async function provisionTenant(
  env: Env,
  req: ProvisionRequest
): Promise<ProvisionResult> {
  const slug = sanitizeSlug(req.slug);

  // ── Idempotency check ────────────────────────────────────────────────────
  const existing = await env.PLATFORM_DB
    .prepare('SELECT * FROM tenants WHERE org_id = ?')
    .bind(req.orgId)
    .first<TenantRecord>();

  if (existing?.status === 'active') {
    return {
      success: true,
      tenantId: existing.id,
      workerUrl: `https://${existing.customDomain}`,
      customDomain: existing.customDomain,
    };
  }

  // ── Lock ─────────────────────────────────────────────────────────────────
  const locked = await acquireLock(env, req.orgId);
  if (!locked) {
    return { success: false, error: 'Provisioning already in progress for this org' };
  }

  const tenantId = crypto.randomUUID();
  const wkName = workerName(slug);
  const domain = tenantDomain(slug, env.BASE_DOMAIN);
  const provisioned: ProvisionedResources = {};

  // Insert a 'provisioning' record immediately so we can track progress
  await env.PLATFORM_DB.prepare(`
    INSERT INTO tenants (id, org_id, user_id, email, slug, tier, worker_name, custom_domain, status, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'provisioning', datetime('now'), datetime('now'))
    ON CONFLICT(org_id) DO UPDATE SET status = 'provisioning', updated_at = datetime('now')
  `).bind(tenantId, req.orgId, req.userId, req.email, slug, req.tier, wkName, domain).run();

  try {
    // ── 1. Load build artifacts from R2 ─────────────────────────────────────
    console.log(`[${slug}] Loading build artifacts…`);
    const [schemaSql, workerBundle] = await Promise.all([
      loadSchema(env),
      loadWorkerBundle(env),
    ]);

    // ── 2. Create D1 database ────────────────────────────────────────────────
    console.log(`[${slug}] Creating D1 database…`);
    const d1 = await createD1Database(env, d1Name(slug));
    provisioned.d1DatabaseId = d1.uuid;

    // ── 3. Run schema migrations ─────────────────────────────────────────────
    console.log(`[${slug}] Running schema migrations on ${d1.uuid}…`);
    await migrateD1Database(env, d1.uuid, schemaSql);

    // ── 4. Create KV namespace ───────────────────────────────────────────────
    console.log(`[${slug}] Creating KV namespace…`);
    const kv = await createKVNamespace(env, kvName(slug));
    provisioned.kvNamespaceId = kv.id;

    // ── 5. Create R2 bucket ──────────────────────────────────────────────────
    console.log(`[${slug}] Creating R2 bucket…`);
    const r2BucketName = r2Name(slug);
    await createR2Bucket(env, r2BucketName);
    provisioned.r2BucketName = r2BucketName;

    // ── 6. Upload worker to dispatch namespace ───────────────────────────────
    console.log(`[${slug}] Uploading worker to dispatch namespace…`);

    // Retrieve per-tenant secrets from platform KV
    // (Auth service stored them there during signup, keyed by orgId)
    const tenantSecrets = await env.PLATFORM_KV.get<{
      authJwtSecret: string;
      openAiApiKey: string;
      qbClientId: string;
      qbClientSecret: string;
      stripeWebhookSecret: string;
    }>(`tenant_secrets:${req.orgId}`, 'json');

    if (!tenantSecrets) {
      throw new Error(`Tenant secrets not found for org ${req.orgId} — auth service must write them first`);
    }

    await uploadTenantWorker(env, {
      workerName: wkName,
      scriptBundle: workerBundle,
      d1DatabaseId: d1.uuid,
      d1DatabaseName: d1Name(slug),
      kvNamespaceId: kv.id,
      r2BucketName,
      orgId: req.orgId,
      tier: req.tier,
      baseUrl: `https://${domain}`,
      ...tenantSecrets,
    });
    provisioned.workerName = wkName;

    // Clean up secrets from KV — they're now baked into the worker bindings
    await env.PLATFORM_KV.delete(`tenant_secrets:${req.orgId}`);

    // ── 7. Create DNS record ─────────────────────────────────────────────────
    console.log(`[${slug}] Creating DNS record for ${domain}…`);
    const subdomain = `${slug}.bookkeeping`; // → acme-consulting.bookkeeping
    const dnsRecord = await createTenantDNSRecord(env, subdomain);
    provisioned.dnsRecordId = dnsRecord.id;

    // ── 8. Attach custom domain to worker ────────────────────────────────────
    console.log(`[${slug}] Attaching custom domain ${domain}…`);
    await attachCustomDomain(env, wkName, domain);

    // ── 9. Mark tenant as active ─────────────────────────────────────────────
    await env.PLATFORM_DB.prepare(`
      UPDATE tenants SET
        status = 'active',
        d1_database_id = ?,
        d1_database_name = ?,
        kv_namespace_id = ?,
        kv_namespace_name = ?,
        r2_bucket_name = ?,
        dns_record_id = ?,
        provisioned_at = datetime('now'),
        updated_at = datetime('now')
      WHERE org_id = ?
    `).bind(
      d1.uuid,
      d1Name(slug),
      kv.id,
      kvName(slug),
      r2BucketName,
      dnsRecord.id,
      req.orgId
    ).run();

    // ── 10. Cache tenant lookup in KV ────────────────────────────────────────
    await env.PLATFORM_KV.put(
      `tenant:${req.orgId}`,
      JSON.stringify({ workerName: wkName, domain, slug }),
      { expirationTtl: 86400 }  // 24h cache
    );

    // Analytics
    env.ANALYTICS.writeDataPoint({
      blobs: ['tenant_provisioned', req.tier],
      doubles: [1],
      indexes: [req.orgId],
    });

    console.log(`[${slug}] ✓ Provisioning complete — https://${domain}`);

    return {
      success: true,
      tenantId,
      workerUrl: `https://${domain}`,
      customDomain: domain,
    };

  } catch (err) {
    console.error(`[${slug}] Provisioning failed:`, err);

    // Saga rollback
    await rollback(env, provisioned);

    // Mark tenant as failed in DB
    await env.PLATFORM_DB.prepare(`
      UPDATE tenants SET status = 'provisioning', updated_at = datetime('now') WHERE org_id = ?
    `).bind(req.orgId).run().catch(() => {});

    // Analytics
    env.ANALYTICS.writeDataPoint({
      blobs: ['tenant_provision_failed', req.tier],
      doubles: [1],
      indexes: [req.orgId],
    });

    return {
      success: false,
      error: err instanceof Error ? err.message : 'Provisioning failed',
    };

  } finally {
    await releaseLock(env, req.orgId);
  }
}

// ─── Deprovision ─────────────────────────────────────────────────────────────

/**
 * Tear down all resources for a tenant (account deletion / GDPR).
 * Marks tenant as 'deprovisioning', destroys all CF resources, then 'deleted'.
 */
export async function deprovisionTenant(
  env: Env,
  orgId: string
): Promise<{ success: boolean; error?: string }> {
  const tenant = await env.PLATFORM_DB
    .prepare('SELECT * FROM tenants WHERE org_id = ?')
    .bind(orgId)
    .first<TenantRecord>();

  if (!tenant) return { success: false, error: 'Tenant not found' };
  if (tenant.status === 'deleted') return { success: true }; // Already gone

  // Mark as deprovisioning
  await env.PLATFORM_DB.prepare(
    `UPDATE tenants SET status = 'deprovisioning', updated_at = datetime('now') WHERE org_id = ?`
  ).bind(orgId).run();

  const results = await Promise.allSettled([
    deleteTenantWorker(env, tenant.workerName),
    deleteD1Database(env, tenant.d1DatabaseId),
    deleteKVNamespace(env, tenant.kvNamespaceId),
    deleteR2Bucket(env, tenant.r2BucketName),
    deleteDNSRecord(env, tenant.dnsRecordId),
  ]);

  const failures = results
    .filter((r) => r.status === 'rejected')
    .map((r) => (r as PromiseRejectedResult).reason?.message);

  if (failures.length > 0) {
    console.error(`Deprovision partial failure for ${orgId}:`, failures);
    // Don't hard-fail — continue to mark deleted and clean up KV
  }

  // Remove KV cache
  await env.PLATFORM_KV.delete(`tenant:${orgId}`);

  // Mark deleted with timestamp
  await env.PLATFORM_DB.prepare(`
    UPDATE tenants SET status = 'deleted', deleted_at = datetime('now'), updated_at = datetime('now')
    WHERE org_id = ?
  `).bind(orgId).run();

  env.ANALYTICS.writeDataPoint({
    blobs: ['tenant_deprovisioned'],
    doubles: [1],
    indexes: [orgId],
  });

  return { success: true };
}

// ─── Tier upgrade ─────────────────────────────────────────────────────────────

/**
 * When a tenant upgrades their plan, re-upload their worker with the new tier
 * binding so TIER env var reflects the new plan without reprovisioning resources.
 */
export async function updateTenantTier(
  env: Env,
  orgId: string,
  newTier: 'free' | 'standard' | 'pro'
): Promise<void> {
  const tenant = await env.PLATFORM_DB
    .prepare('SELECT * FROM tenants WHERE org_id = ?')
    .bind(orgId)
    .first<TenantRecord>();

  if (!tenant || tenant.status !== 'active') {
    throw new Error(`Cannot update tier for non-active tenant ${orgId}`);
  }

  const workerBundle = await loadWorkerBundle(env);

  const tenantSecrets = await env.PLATFORM_KV.get<{
    authJwtSecret: string;
    openAiApiKey: string;
    qbClientId: string;
    qbClientSecret: string;
    stripeWebhookSecret: string;
  }>(`tenant_secrets:${orgId}`, 'json');

  // Fall back to blank secrets if not present (they're already in the worker)
  const secrets = tenantSecrets ?? {
    authJwtSecret: '',
    openAiApiKey: '',
    qbClientId: '',
    qbClientSecret: '',
    stripeWebhookSecret: '',
  };

  await uploadTenantWorker(env, {
    workerName: tenant.workerName,
    scriptBundle: workerBundle,
    d1DatabaseId: tenant.d1DatabaseId,
    d1DatabaseName: tenant.d1DatabaseName,
    kvNamespaceId: tenant.kvNamespaceId,
    r2BucketName: tenant.r2BucketName,
    orgId,
    tier: newTier,
    baseUrl: `https://${tenant.customDomain}`,
    ...secrets,
  });

  await env.PLATFORM_DB.prepare(
    `UPDATE tenants SET tier = ?, updated_at = datetime('now') WHERE org_id = ?`
  ).bind(newTier, orgId).run();

  // Invalidate tenant lookup cache
  await env.PLATFORM_KV.delete(`tenant:${orgId}`);

  env.ANALYTICS.writeDataPoint({
    blobs: ['tenant_tier_updated', newTier],
    doubles: [1],
    indexes: [orgId],
  });
}
