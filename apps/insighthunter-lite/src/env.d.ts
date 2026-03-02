// apps/insighthunter-lite/src/env.d.ts
/// <reference types="astro/client" />
/// <reference types="@cloudflare/workers-types" />

interface Env {
  DB: D1Database;
  STORAGE: R2Bucket;
  SESSIONS: KVNamespace;
  AI: Ai;
  ANALYTICS: AnalyticsEngineDataset;
  ASSETS: Fetcher;
  ENVIRONMENT: string;
  AUTH_SERVICE_URL: string;
  MAX_CSV_ROWS: string;
}

type Runtime = import('@astrojs/cloudflare').Runtime<Env>;

declare namespace App {
  interface Locals extends Runtime {
    userId: string | null;
    sessionToken: string | null;
  }
}
