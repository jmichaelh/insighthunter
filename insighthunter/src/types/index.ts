// ─── Auth ───────────────────────────────────────────────────────────────────
export interface AuthUser {
  id: string;
  email: string;
  name: string;
  orgId: string;
  tier: Tier;
  avatar?: string;
  createdAt: string;
}

export interface Session {
  token: string;
  userId: string;
  expiresAt: number;
}

export interface OrgContext {
  id: string;
  name: string;
  tier: Tier;
  seats: number;
}

// ─── Apps / Tiers ────────────────────────────────────────────────────────────
export type Tier = 'free' | 'lite' | 'standard' | 'pro' | 'white-label';

export interface AppDefinition {
  slug: string;
  name: string;
  description: string;
  shortDesc: string;
  icon: string;
  tier: Tier;
  route: string;
  color: string;
  badge?: string;
}

export interface FeatureFlag {
  key: string;
  label: string;
  tiers: Tier[];
}

// ─── Pricing ─────────────────────────────────────────────────────────────────
export interface PricingPlan {
  id: string;
  name: string;
  slug: string;
  price: number; // monthly, 0 = free
  annualPrice?: number;
  oneTime?: boolean;
  description: string;
  highlight?: boolean;
  badge?: string;
  stripePriceId: string;
  stripeAnnualPriceId?: string;
  features: string[];
  notIncluded?: string[];
  cta: string;
  tier: Tier;
}

// ─── Cart ────────────────────────────────────────────────────────────────────
export interface CartItem {
  planId: string;
  planName: string;
  price: number;
  billing: 'monthly' | 'annual' | 'one-time';
  stripePriceId: string;
  quantity: number;
}

export interface Cart {
  items: CartItem[];
  total: number;
}

// ─── API ─────────────────────────────────────────────────────────────────────
export interface ApiResponse<T = unknown> {
  ok: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// ─── Cloudflare Env ──────────────────────────────────────────────────────────
export interface Env {
  DB: D1Database;
  SESSIONS: KVNamespace;
  STORAGE: R2Bucket;
  EMAIL_QUEUE: Queue;
  ANALYTICS: AnalyticsEngineDataset;
  AUTH_WORKER_URL: string;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  STRIPE_PUBLISHABLE_KEY: string;
  JWT_SECRET: string;
  APP_URL: string;
  APP_ENV: string;
}
