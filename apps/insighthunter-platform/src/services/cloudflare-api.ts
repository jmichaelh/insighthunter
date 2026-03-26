// apps/insighthunter-platform/src/services/cloudflare-api.ts
// Wrapper around the Cloudflare REST API for programmatic resource provisioning.
// Called once per new tenant during signup.

import {
  Env,
  CFApiResponse,
  CFD1Database,
  CFKVNamespace,
  CFR2Bucket,
  CFWorkerUpload,
  CFDNSRecord,
} from '../types/index.js';

const CF_API = 'https://api.cloudflare.com/client/v4';

// ─── Base request helper ──────────────────────────────────────────────────────

async function cfRequest<T>(
  env: Env,
  path: string,
  options: RequestInit = {}
): Promise<CFApiResponse<T>> {
  const url = `${CF_API}${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${env.CF_API_TOKEN}`,
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
  });

  const data: CFApiResponse<T> = await res.json();

  if (!data.success) {
    const errMsg = data.errors?.map((e) => `${e.code}: ${e.message}`).join(', ');
    throw new Error(`Cloudflare API error on ${path}: ${errMsg}`);
  }

  return data;
}

// ─── D1 ───────────────────────────────────────────────────────────────────────

/**
 * Create a new D1 database for a tenant.
 * Returns the database UUID needed for worker bindings.
 */
export async function createD1Database(
  env: Env,
  name: string
): Promise<CFD1Database> {
  const res = await cfRequest<CFD1Database>(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/d1/database`,
    {
      method: 'POST',
      body: JSON.stringify({ name }),
    }
  );
  return res.result;
}

/**
 * Run the bookkeeping schema SQL against a newly created D1 database.
 * The schema SQL is stored in R2 as 'schema.sql' at deploy time.
 */
export async function migrateD1Database(
  env: Env,
  databaseId: string,
  schemaSql: string
): Promise<void> {
  // Split on semicolons and run each statement as a batch
  const statements = schemaSql
    .split(';')
    .map((s) => s.trim())
    .filter((s) => s.length > 0 && !s.startsWith('--'));

  // CF D1 REST API executes SQL statements
  await cfRequest(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/d1/database/${databaseId}/query`,
    {
      method: 'POST',
      body: JSON.stringify({ sql: statements.join(';\n') + ';' }),
    }
  );
}

/**
 * Delete a D1 database (deprovision).
 */
export async function deleteD1Database(
  env: Env,
  databaseId: string
): Promise<void> {
  await cfRequest(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/d1/database/${databaseId}`,
    { method: 'DELETE' }
  );
}

// ─── KV ───────────────────────────────────────────────────────────────────────

/**
 * Create a new KV namespace for a tenant.
 */
export async function createKVNamespace(
  env: Env,
  title: string
): Promise<CFKVNamespace> {
  const res = await cfRequest<CFKVNamespace>(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/storage/kv/namespaces`,
    {
      method: 'POST',
      body: JSON.stringify({ title }),
    }
  );
  return res.result;
}

/**
 * Delete a KV namespace (deprovision).
 */
export async function deleteKVNamespace(
  env: Env,
  namespaceId: string
): Promise<void> {
  await cfRequest(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/storage/kv/namespaces/${namespaceId}`,
    { method: 'DELETE' }
  );
}

// ─── R2 ───────────────────────────────────────────────────────────────────────

/**
 * Create a new R2 bucket for a tenant.
 */
export async function createR2Bucket(
  env: Env,
  bucketName: string
): Promise<CFR2Bucket> {
  const res = await cfRequest<CFR2Bucket>(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/r2/buckets`,
    {
      method: 'POST',
      body: JSON.stringify({ name: bucketName }),
    }
  );
  return res.result;
}

/**
 * Delete an R2 bucket (deprovision).
 */
export async function deleteR2Bucket(
  env: Env,
  bucketName: string
): Promise<void> {
  await cfRequest(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/r2/buckets/${bucketName}`,
    { method: 'DELETE' }
  );
}

// ─── Workers for Platforms — User Worker Upload ───────────────────────────────

/**
 * Upload a tenant worker script into the dispatch namespace.
 *
 * Uses the Workers for Platforms script upload API which attaches
 * per-tenant bindings (D1, KV, R2) at upload time.
 *
 * The worker *script* is the same compiled bundle for every tenant —
 * isolation comes from the unique resource bindings, not code divergence.
 */
export async function uploadTenantWorker(
  env: Env,
  params: {
    workerName: string;
    scriptBundle: ArrayBuffer;   // Compiled worker JS (from R2)
    d1DatabaseId: string;
    d1DatabaseName: string;
    kvNamespaceId: string;
    r2BucketName: string;
    orgId: string;
    tier: string;
    authJwtSecret: string;
    openAiApiKey: string;
    qbClientId: string;
    qbClientSecret: string;
    stripeWebhookSecret: string;
    baseUrl: string;             // e.g. https://acme.bookkeeping.insighthunter.app
  }
): Promise<CFWorkerUpload> {
  // Build multipart form — script + metadata with bindings
  const metadata = {
    main_module: 'index.js',
    compatibility_date: '2025-03-07',
    compatibility_flags: ['nodejs_compat'],
    bindings: [
      // D1 — tenant-isolated database
      {
        type: 'd1',
        name: 'DB',
        id: params.d1DatabaseId,
      },
      // KV — session cache and rate limits
      {
        type: 'kv_namespace',
        name: 'BOOKKEEPING_KV',
        namespace_id: params.kvNamespaceId,
      },
      // R2 — file uploads and exports
      {
        type: 'r2_bucket',
        name: 'BOOKKEEPING_FILES',
        bucket_name: params.r2BucketName,
      },
      // Workers AI — shared, no per-tenant binding needed
      {
        type: 'ai',
        name: 'AI',
      },
      // Plain text vars
      { type: 'plain_text', name: 'ORG_ID', text: params.orgId },
      { type: 'plain_text', name: 'TIER', text: params.tier },
      { type: 'plain_text', name: 'ENVIRONMENT', text: 'production' },
      { type: 'plain_text', name: 'BASE_URL', text: params.baseUrl },
      { type: 'plain_text', name: 'AUTH_SERVICE_URL', text: 'https://auth.insighthunter.app' },
      { type: 'plain_text', name: 'REPORTS_SERVICE_URL', text: 'https://reports.insighthunter.app' },
      { type: 'plain_text', name: 'PAYROLL_SERVICE_URL', text: 'https://payroll.insighthunter.app' },
      { type: 'plain_text', name: 'QB_REDIRECT_URI', text: `${params.baseUrl}/api/integrations/qb/callback` },
      // Secrets (encrypted at rest by Cloudflare)
      { type: 'secret_text', name: 'AUTH_JWT_SECRET', text: params.authJwtSecret },
      { type: 'secret_text', name: 'OPENAI_API_KEY', text: params.openAiApiKey },
      { type: 'secret_text', name: 'QB_CLIENT_ID', text: params.qbClientId },
      { type: 'secret_text', name: 'QB_CLIENT_SECRET', text: params.qbClientSecret },
      { type: 'secret_text', name: 'STRIPE_WEBHOOK_SECRET', text: params.stripeWebhookSecret },
    ],
    // Queues: provisioned as shared infra — messages are tagged with orgId
    // so tenants don't need isolated queues (queue processing is server-side only)
    observability: { enabled: true, head_sampling_rate: 1 },
  };

  const form = new FormData();
  form.append(
    'metadata',
    new Blob([JSON.stringify(metadata)], { type: 'application/json' }),
    'metadata.json'
  );
  form.append(
    'index.js',
    new Blob([params.scriptBundle], { type: 'application/javascript+module' }),
    'index.js'
  );

  // Upload to the dispatch namespace
  const res = await fetch(
    `${CF_API}/accounts/${env.CF_ACCOUNT_ID}/workers/dispatch/namespaces/${env.DISPATCH_NAMESPACE_NAME}/scripts/${params.workerName}`,
    {
      method: 'PUT',
      headers: { Authorization: `Bearer ${env.CF_API_TOKEN}` },
      body: form,
    }
  );

  const data: CFApiResponse<CFWorkerUpload> = await res.json();
  if (!data.success) {
    const errMsg = data.errors?.map((e) => `${e.code}: ${e.message}`).join(', ');
    throw new Error(`Worker upload failed: ${errMsg}`);
  }

  return data.result;
}

/**
 * Delete a tenant worker from the dispatch namespace (deprovision).
 */
export async function deleteTenantWorker(
  env: Env,
  workerName: string
): Promise<void> {
  await cfRequest(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/workers/dispatch/namespaces/${env.DISPATCH_NAMESPACE_NAME}/scripts/${workerName}`,
    { method: 'DELETE' }
  );
}

// ─── Custom Domain / DNS ──────────────────────────────────────────────────────

/**
 * Create a DNS CNAME record for the tenant subdomain.
 * e.g. acme-consulting.bookkeeping.insighthunter.app → dispatch worker
 */
export async function createTenantDNSRecord(
  env: Env,
  subdomain: string   // e.g. "acme-consulting.bookkeeping"
): Promise<CFDNSRecord> {
  const res = await cfRequest<CFDNSRecord>(
    env,
    `/zones/${env.CF_ZONE_ID}/dns_records`,
    {
      method: 'POST',
      body: JSON.stringify({
        type: 'CNAME',
        name: subdomain,                          // acme-consulting.bookkeeping
        content: `${env.DISPATCH_NAMESPACE_NAME}.workers.dev`, // Dispatch namespace
        proxied: true,                            // Through Cloudflare — required for Workers
        ttl: 1,                                   // Auto TTL
        comment: `InsightHunter tenant: ${subdomain}`,
      }),
    }
  );
  return res.result;
}

/**
 * Attach a custom hostname to a specific tenant worker in the dispatch namespace.
 * This uses the Workers for Platforms custom domains API.
 */
export async function attachCustomDomain(
  env: Env,
  workerName: string,
  hostname: string    // e.g. acme-consulting.bookkeeping.insighthunter.app
): Promise<void> {
  // Add hostname routing to the specific user worker
  await cfRequest(
    env,
    `/accounts/${env.CF_ACCOUNT_ID}/workers/dispatch/namespaces/${env.DISPATCH_NAMESPACE_NAME}/scripts/${workerName}/domains`,
    {
      method: 'POST',
      body: JSON.stringify({ hostname }),
    }
  );
}

/**
 * Delete a tenant's DNS record (deprovision).
 */
export async function deleteDNSRecord(
  env: Env,
  recordId: string
): Promise<void> {
  await cfRequest(
    env,
    `/zones/${env.CF_ZONE_ID}/dns_records/${recordId}`,
    { method: 'DELETE' }
  );
}
