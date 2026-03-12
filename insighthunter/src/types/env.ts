export interface Env {
  // D1
  DB: D1Database;

  // KV
  CACHE:      KVNamespace;
  RATE_LIMIT: KVNamespace;

  // R2
  REPORTS_BUCKET: R2Bucket;

  // Queues
  REPORT_QUEUE:       Queue;
  NOTIFICATION_QUEUE: Queue;

  // Analytics
  EVENTS: AnalyticsEngineDataset;

  // Vars
  APP_ENV:                 string;
  APP_TIER:                string;
  AUTH_SERVICE_URL:        string;
  AGENTS_SERVICE_URL:      string;
  BOOKKEEPING_SERVICE_URL: string;
  CORS_ORIGIN:             string;
  RATE_LIMIT_WINDOW:       string;
  RATE_LIMIT_MAX:          string;

  // Secrets
  JWT_SECRET:      string;
  SERVICE_API_KEY: string;
}
