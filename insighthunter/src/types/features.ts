// ════════════════════════════════════════════════════════════════════════
// InsightHunter — Feature & App Type System
// src/types/features.ts
// ════════════════════════════════════════════════════════════════════════

// ── Tiers ─────────────────────────────────────────────────────────────
export type Tier = 'lite' | 'standard' | 'pro' | 'enterprise';

export const TIERS: Tier[] = ['lite', 'standard', 'pro', 'enterprise'];

export const TIER_RANK: Record<Tier, number> = {
  lite:       0,
  standard:   1,
  pro:        2,
  enterprise: 3,
};

/** Returns true if `userTier` meets or exceeds `requiredTier`. */
export function tierSatisfies(userTier: Tier, requiredTier: Tier): boolean {
  return TIER_RANK[userTier] >= TIER_RANK[requiredTier];
}

// ── Feature categories ─────────────────────────────────────────────────
export type FeatureCategory =
  | 'analytics'
  | 'bookkeeping'
  | 'formation'
  | 'ai'
  | 'reporting'
  | 'payroll'
  | 'collaboration'
  | 'integrations'
  | 'platform';

export const FEATURE_CATEGORIES: FeatureCategory[] = [
  'analytics',
  'bookkeeping',
  'formation',
  'ai',
  'reporting',
  'payroll',
  'collaboration',
  'integrations',
  'platform',
];

export const CATEGORY_META: Record<FeatureCategory, {
  label:       string;
  icon:        string;
  description: string;
  pageHref:    string;
}> = {
  analytics: {
    label:       'Analytics',
    icon:        '📊',
    description: 'Real-time KPIs, burn rate, runway, and cash forecasting.',
    pageHref:    '/features/analytics',
  },
  bookkeeping: {
    label:       'Bookkeeping',
    icon:        '📒',
    description: 'Chart of accounts, bank feeds, reconciliation, journal entries.',
    pageHref:    '/features/bookkeeping',
  },
  formation: {
    label:       'Formation',
    icon:        '🏛️',
    description: 'AI entity wizard, EIN guidance, compliance calendar.',
    pageHref:    '/features/formation',
  },
  ai: {
    label:       'AI CFO',
    icon:        '🤖',
    description: 'Insights, anomaly detection, and plain-English financial chat.',
    pageHref:    '/features/ai',
  },
  reporting: {
    label:       'Reports',
    icon:        '📋',
    description: 'GAAP-structured P&L, balance sheet, and cash flow exports.',
    pageHref:    '/features/reporting',
  },
  payroll: {
    label:       'Payroll',
    icon:        '💸',
    description: 'Payroll runs, W-4 / 1099 management, journal sync.',
    pageHref:    '/features/payroll',
  },
  collaboration: {
    label:       'Collaboration',
    icon:        '👥',
    description: 'Team seats, white-label branding, and client workspaces.',
    pageHref:    '/features/collaboration',
  },
  integrations: {
    label:       'Integrations',
    icon:        '🔗',
    description: 'QuickBooks, Xero, Plaid bank feeds.',
    pageHref:    '/features/integrations',
  },
  platform: {
    label:       'Platform',
    icon:        '⚙️',
    description: 'PWA, 99.99% SLA, and dedicated onboarding.',
    pageHref:    '/features/platform',
  },
};

// ── Core Feature type ──────────────────────────────────────────────────
export interface Feature {
  /** Unique snake_case identifier — used in API flags, KV keys, URL slugs. */
  key:          string;

  /** Human-readable label shown in UI. */
  label:        string;

  /** One-sentence description shown on feature cards and detail pages. */
  description:  string;

  /** Which category this feature belongs to. */
  category:     FeatureCategory;

  /** Which tiers include this feature. */
  tiers:        Tier[];

  /** If true, renders "Coming Soon" ribbon and disables links. */
  comingSoon?:  boolean;

  /** Optional external docs or marketing page deep-link. */
  learnMoreHref?: string;

  /** Optional icon override (emoji or icon key). */
  icon?: string;
}

// ── Feature flag (per-org runtime override) ────────────────────────────
export interface FeatureFlag {
  /** Matches Feature.key. */
  featureKey:   string;

  /** Organization this flag applies to. */
  orgId:        string;

  /** Override enabled state (true = force-on even below tier). */
  enabled:      boolean;

  /** Optional expiry — after this date, flag is ignored. */
  expiresAt?:   string;  // ISO 8601

  /** Who set this flag and why (for audit log). */
  setBy?:       string;
  reason?:      string;
}

// ── App definition ─────────────────────────────────────────────────────
/** A top-level InsightHunter product/app (InsightHunter, BizForma, etc.). */
export interface AppDefinition {
  /** Unique slug — used in routes and data keys. */
  id:           string;

  /** Display name shown in nav and cards. */
  name:         string;

  /** Emoji or icon URL. */
  icon:         string;

  /** One-sentence marketing description. */
  description:  string;

  /** The minimum tier required to access this app. */
  tier:         Tier;

  /** Route to the app's feature marketing page. */
  featurePage:  string;

  /** Route to the app inside the dashboard (if live). */
  dashboardHref?: string;

  /** Whether this app is currently available. */
  available:    boolean;

  /** If true, shows "Coming Soon" ribbon on AppCard. */
  comingSoon?:  boolean;

  /** Feature keys that belong to this app, for cross-referencing. */
  featureKeys?: string[];
}

// ── Pricing ────────────────────────────────────────────────────────────
export interface PricingTier {
  tier:          Tier;
  name:          string;
  monthlyPrice:  number | null;   // null = custom/contact sales
  annualPrice:   number | null;   // per month, billed annually
  description:   string;
  highlighted?:  boolean;         // "Most Popular" marker
  ctaLabel:      string;
  ctaHref:       string;
  features:      PricingLineItem[];
}

export interface PricingLineItem {
  label:        string;
  included:     boolean | 'partial';  // partial = limited version
  detail?:      string;               // e.g. "5 per month"
}

// ── Feature gate result ────────────────────────────────────────────────
/** Returned by `checkFeatureAccess()` to explain why access was granted/denied. */
export interface FeatureGateResult {
  allowed:       boolean;
  reason:        FeatureGateReason;
  requiredTier?: Tier;     // set when blocked due to tier
  featureKey:    string;
  orgId:         string;
}

export type FeatureGateReason =
  | 'tier_sufficient'      // user's tier covers the feature
  | 'flag_override'        // org has an explicit feature flag enabled
  | 'tier_insufficient'    // user needs to upgrade
  | 'coming_soon'          // feature not yet launched
  | 'flag_disabled'        // explicitly disabled via flag
  | 'feature_not_found';   // feature key doesn't exist

// ── Tier display helpers ───────────────────────────────────────────────
export const TIER_LABELS: Record<Tier, string> = {
  lite:       'Free',
  standard:   'Standard',
  pro:        'Pro',
  enterprise: 'Enterprise',
};

export const TIER_DESCRIPTIONS: Record<Tier, string> = {
  lite:       'For solopreneurs getting started.',
  standard:   'For growing businesses ready to get serious.',
  pro:        'For teams and fractional CFOs managing multiple clients.',
  enterprise: 'For firms needing white-label and custom SLAs.',
};

export const TIER_PRICES: Record<Tier, { monthly: number | null; annual: number | null }> = {
  lite:       { monthly: 0,    annual: 0    },
  standard:   { monthly: 99,   annual: 79   },
  pro:        { monthly: 199,  annual: 159  },
  enterprise: { monthly: null, annual: null },
};

export const TIER_BADGE_VARIANT: Record<Tier, 'success' | 'info' | 'warning' | 'tan'> = {
  lite:       'success',
  standard:   'info',
  pro:        'warning',
  enterprise: 'tan',
};

export const TIER_COLOR: Record<Tier, string> = {
  lite:       'var(--color-success)',
  standard:   'var(--color-info)',
  pro:        'var(--color-warning)',
  enterprise: 'var(--color-sand-600)',
};

// ── Feature limit types ────────────────────────────────────────────────
/**
 * Some features are available at lower tiers but with usage limits.
 * This type captures those limits per tier.
 */
export interface FeatureLimits {
  featureKey:    string;
  limits:        Partial<Record<Tier, FeatureLimit>>;
}

export type FeatureLimit =
  | { type: 'count';    max: number }        // e.g. 5 AI insights/month
  | { type: 'seats';    max: number }        // e.g. 3 users
  | { type: 'storage';  maxMB: number }      // e.g. 500MB uploads
  | { type: 'clients';  max: number }        // e.g. 10 client orgs
  | { type: 'unlimited'              };      // no cap

export const FEATURE_LIMITS: FeatureLimits[] = [
  {
    featureKey: 'ai_insights_limited',
    limits: {
      lite:     { type: 'count', max: 5      },
      standard: { type: 'unlimited'          },
      pro:      { type: 'unlimited'          },
      enterprise:{ type: 'unlimited'         },
    },
  },
  {
    featureKey: 'team_3',
    limits: {
      lite:     { type: 'seats', max: 1      },
      standard: { type: 'seats', max: 3      },
      pro:      { type: 'unlimited'          },
      enterprise:{ type: 'unlimited'         },
    },
  },
  {
    featureKey: 'csv_upload',
    limits: {
      lite:     { type: 'storage', maxMB: 50  },
      standard: { type: 'storage', maxMB: 500 },
      pro:      { type: 'unlimited'           },
      enterprise:{ type: 'unlimited'          },
    },
  },
  {
    featureKey: 'multi_client_dashboard',
    limits: {
      pro:       { type: 'clients', max: 25  },
      enterprise:{ type: 'unlimited'         },
    },
  },
];

// ── Upgrade prompt ─────────────────────────────────────────────────────
/** Shown when a user hits a feature gate — drives the upgrade modal. */
export interface UpgradePrompt {
  featureKey:    string;
  featureLabel:  string;
  currentTier:   Tier;
  requiredTier:  Tier;
  headline:      string;
  body:          string;
  ctaLabel:      string;
  ctaHref:       string;
}

export function buildUpgradePrompt(
  feature:     Feature,
  currentTier: Tier,
): UpgradePrompt {
  const requiredTier = feature.tiers[0] ?? 'standard';
  return {
    featureKey:   feature.key,
    featureLabel: feature.label,
    currentTier,
    requiredTier,
    headline:     `${feature.label} requires ${TIER_LABELS[requiredTier]}`,
    body:         `Upgrade to ${TIER_LABELS[requiredTier]} to unlock ${feature.label}. ${feature.description}`,
    ctaLabel:     `Upgrade to ${TIER_LABELS[requiredTier]}`,
    ctaHref:      `/pricing?highlight=${requiredTier}`,
  };
}

// ── Re-exports ─────────────────────────────────────────────────────────
// Convenience: barrel export so consumers can import from one place.
export type {
  Feature        as IFeature,
  AppDefinition  as IApp,
  PricingTier    as IPricingTier,
  FeatureFlag    as IFeatureFlag,
  FeatureGateResult as IGateResult,
};
