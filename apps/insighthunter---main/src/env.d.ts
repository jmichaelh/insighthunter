/// <reference path="../.astro/types.d.ts" />
// apps/insighthunter-main/src/env.d.ts
/// <reference types="astro/client" />
/// <reference types="@cloudflare/workers-types" />

type Plan = 'lite' | 'standard' | 'pro';

interface CloudflareEnv {
  ASSETS:        Fetcher;
  AUTH_WORKER:   Fetcher;
  AGENTS_WORKER: Fetcher;
  SESSIONS:      KVNamespace;
  EVENTS:        AnalyticsEngineDataset;
  APP_URL:       string;
  APP_ENV:       string;
  APP_VERSION:   string;
}

declare namespace App {
  interface Locals {
    // Injected by worker.ts via X-IH-* headers
    userId: string | null;
    plan:   Plan   | null;
    // Cloudflare runtime (bindings, cf object, ctx)
    runtime: {
      env: CloudflareEnv;
      cf:  CfProperties;
      ctx: ExecutionContext;
    };
  }
}

interface ImportMetaEnv {
  readonly APP_URL:     string;
  readonly APP_ENV:     string;
  readonly APP_VERSION: string;
}
