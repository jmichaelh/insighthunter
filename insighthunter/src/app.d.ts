import type { SessionData } from '$lib/server/auth';

declare global {
  namespace App {
    interface Locals {
      session: SessionData | null;
    }
    interface Platform {
      env: {
        IH_SESSIONS: KVNamespace;
        IH_DB: D1Database;
        QB_CLIENT_ID: string;
        QB_CLIENT_SECRET: string;
      };
    }
  }
}

export {};
