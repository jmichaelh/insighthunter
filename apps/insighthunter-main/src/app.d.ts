import type { D1Database, KVNamespace } from '@cloudflare/workers-types';

declare global {
  namespace App {
    interface Locals {
      user?: {
        id: string;
        email: string;
        fullName: string;
        companyName: string;
        plan: string;
        subscriptionStatus: string;
      };
      sessionId?: string;
    }
    interface Platform {
      env: {
        INSIGHTHUNTER_DB: D1Database;
        INSIGHTHUNTER_KV: KVNamespace;
        STRIPE_SECRET_KEY: string;
        STRIPE_WEBHOOK_SECRET: string;
        STRIPE_PUBLISHABLE_KEY: string;
        SESSION_SECRET: string;
        APP_URL: string;
      };
    }
  }
}

export {};
