export interface Env {
  // D1
  DB: D1Database;

  // KV
  SESSIONS: KVNamespace;  // session_token → SessionRecord JSON
  TOKENS:   KVNamespace;  // reset/verify token → userId

  // Analytics Engine
  EVENTS: AnalyticsEngineDataset;

  // Vars
  APP_ENV:           string;
  APP_URL:           string;
  CORS_ORIGIN:       string;
  JWT_EXPIRY:        string;
  REFRESH_EXPIRY:    string;
  RATE_LIMIT_WINDOW: string;
  RATE_LIMIT_MAX:    string;
  BCRYPT_ROUNDS:     string;

  // Secrets
  JWT_SECRET:           string;
  REFRESH_SECRET:       string;
  MAILCHANNELS_API_KEY: string;
}
