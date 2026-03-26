// apps/insighthunter-platform/AUTH_INTEGRATION.md (as code for readability)
// ═══════════════════════════════════════════════════════════════════════════════
// insighthunter-auth Integration Contract
// ═══════════════════════════════════════════════════════════════════════════════
//
// During a new user signup, insighthunter-auth MUST call the platform worker
// in this exact sequence. All calls use X-Platform-Secret for authentication.
//
// PLATFORM_URL = https://bookkeeping.insighthunter.app  (the platform worker)
// PLATFORM_SECRET = shared secret (set via wrangler secret)

/**
 * STEP 1 — Stage secrets (call this FIRST, before /provision)
 *
 * POST https://bookkeeping.insighthunter.app/platform/provision/secrets
 * X-Platform-Secret: <PLATFORM_SECRET>
 *
 * Body:
 * {
 *   "orgId": "org_abc123",
 *   "authJwtSecret": "...",      // The JWT signing secret for this org
 *   "openAiApiKey": "sk-...",    // Per-tenant OpenAI key (or shared platform key)
 *   "qbClientId": "...",         // QuickBooks app client ID
 *   "qbClientSecret": "...",     // QuickBooks app client secret
 *   "stripeWebhookSecret": "whsec_..."  // Per-tenant Stripe webhook secret
 * }
 *
 * Response: { "success": true }
 *
 * Secrets are stored in platform KV with a 15-minute TTL.
 * They are consumed during worker upload and then deleted.
 * They are NEVER stored in D1 or written to logs.
 */

/**
 * STEP 2 — Provision the tenant (call this after secrets are staged)
 *
 * POST https://bookkeeping.insighthunter.app/platform/provision
 * X-Platform-Secret: <PLATFORM_SECRET>
 *
 * Body:
 * {
 *   "orgId": "org_abc123",
 *   "userId": "user_xyz789",
 *   "email": "owner@acmeconsulting.com",
 *   "slug": "acme-consulting",      // Will be sanitized: lowercase, hyphens only
 *   "tier": "free",                 // free | standard | pro
 *   "insightHunterSubscriber": true
 * }
 *
 * Success Response (201):
 * {
 *   "success": true,
 *   "tenantId": "uuid",
 *   "workerUrl": "https://acme-consulting.bookkeeping.insighthunter.app",
 *   "customDomain": "acme-consulting.bookkeeping.insighthunter.app"
 * }
 *
 * Error Response (500):
 * {
 *   "success": false,
 *   "error": "D1 database creation failed: ..."
 * }
 *
 * IDEMPOTENT: Safe to retry. Duplicate calls for the same orgId return the
 * existing tenant data if already active.
 *
 * ASYNC-SAFE: The platform uses a KV lock to prevent race conditions on
 * duplicate webhook deliveries.
 */

/**
 * STEP 3 — Store workerUrl in auth service user record
 *
 * After /provision responds with success, insighthunter-auth should store
 * the workerUrl in the user/org record so the frontend knows where to redirect.
 *
 * The JWT issued by insighthunter-auth should include:
 * {
 *   "userId": "user_xyz789",
 *   "orgId": "org_abc123",
 *   "email": "owner@acmeconsulting.com",
 *   "tier": "free",
 *   "bookkeepingUrl": "https://acme-consulting.bookkeeping.insighthunter.app",
 *   "insightHunterSubscriber": true,
 *   "exp": 1234567890
 * }
 *
 * The bookkeeping worker validates this JWT using the shared AUTH_JWT_SECRET
 * (which is per-tenant, baked into the worker binding at provisioning time).
 */

/**
 * TIER CHANGE — When a subscription upgrades/downgrades
 *
 * PATCH https://bookkeeping.insighthunter.app/platform/tier/:orgId
 * X-Platform-Secret: <PLATFORM_SECRET>
 *
 * Body: { "tier": "standard" }
 *
 * This re-uploads the tenant worker with the new TIER binding.
 * No data is lost. Takes ~2 seconds.
 */

/**
 * ACCOUNT DELETION / GDPR ERASURE
 *
 * DELETE https://bookkeeping.insighthunter.app/platform/deprovision/:orgId
 * X-Platform-Secret: <PLATFORM_SECRET>
 *
 * Destroys: Worker, D1, KV, R2, DNS record.
 * Marks tenant as 'deleted' in platform DB.
 * IRREVERSIBLE.
 */

/**
 * PROVISIONING TIME ESTIMATES
 *
 * D1 create:          ~500ms
 * D1 migrate:         ~800ms
 * KV create:          ~300ms
 * R2 create:          ~400ms
 * Worker upload:      ~1.5s
 * DNS record:         ~400ms
 * Custom domain:      ~500ms
 * ─────────────────────────
 * Total (sequential): ~4.4s
 * Total (parallel*):  ~2.5s  (* D1+KV+R2 created in parallel; worker upload last)
 *
 * Recommendation: Call /provision from a background job/queue in auth,
 * not synchronously in the signup HTTP response. Return the user to a
 * "setting up your workspace…" page that polls /platform/tenant/:orgId
 * until status = 'active'.
 */

/**
 * SUSPENSION (non-payment)
 *
 * POST /platform/tenant/:orgId/suspend
 * POST /platform/tenant/:orgId/unsuspend
 *
 * Suspension marks the tenant record. The dispatch worker checks tenant
 * status on each request and returns 402 Payment Required for suspended tenants.
 */

export {}; // Make TypeScript treat this as a module
