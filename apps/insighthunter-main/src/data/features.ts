import type { Tier } from '@/types/apps';

export interface Feature {
  key:         string;
  label:       string;
  description: string;
  category:    FeatureCategory;
  tiers:       Tier[];          // tiers that include this feature
  comingSoon?: boolean;
}

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

export const FEATURES: Feature[] = [
  // ── Analytics ────────────────────────────────────────────────────────
  {
    key:         'kpi_dashboard',
    label:       'KPI Dashboard',
    description: 'Real-time revenue, expenses, net income, cash on hand, and runway metrics.',
    category:    'analytics',
    tiers:       ['lite', 'standard', 'pro', 'enterprise'],
  },
  {
    key:         'cash_flow_forecast',
    label:       'Cash Flow Forecasting',
    description: 'AI-powered 30/60/90-day cash flow projections based on historical patterns.',
    category:    'analytics',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'burn_rate',
    label:       'Burn Rate & Runway',
    description: 'Automatic burn rate calculation and runway months remaining.',
    category:    'analytics',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'multi_client_dashboard',
    label:       'Multi-Client Dashboard',
    description: 'Switch between client workspaces from a single login — built for fractional CFOs.',
    category:    'analytics',
    tiers:       ['pro', 'enterprise'],
  },

  // ── Reporting ─────────────────────────────────────────────────────────
  {
    key:         'pl_report',
    label:       'Profit & Loss Report',
    description: 'Full P&L statement with period comparison and category breakdowns.',
    category:    'reporting',
    tiers:       ['lite', 'standard', 'pro', 'enterprise'],
  },
  {
    key:         'cash_flow_report',
    label:       'Cash Flow Statement',
    description: 'Operating, investing, and financing activities — GAAP-structured output.',
    category:    'reporting',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'balance_sheet',
    label:       'Balance Sheet',
    description: 'Assets, liabilities, and equity snapshot on demand.',
    category:    'reporting',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'pdf_export',
    label:       'PDF Export',
    description: 'Export any report as a branded, client-ready PDF.',
    category:    'reporting',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'csv_upload',
    label:       'CSV Upload & Ingestion',
    description: 'Upload bank statements or transaction exports as CSV for instant analysis.',
    category:    'reporting',
    tiers:       ['lite', 'standard', 'pro', 'enterprise'],
  },

  // ── AI ────────────────────────────────────────────────────────────────
  {
    key:         'ai_insights_limited',
    label:       'AI Insights (5/month)',
    description: 'AI-generated financial insights and anomaly alerts — capped at 5 per month.',
    category:    'ai',
    tiers:       ['lite'],
  },
  {
    key:         'ai_insights_unlimited',
    label:       'Unlimited AI Insights',
    description: 'Continuous AI CFO insights — anomalies, opportunities, and cash warnings.',
    category:    'ai',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'ai_cfo_chat',
    label:       'AI CFO Chat',
    description: 'Ask questions about your finances in plain English. Get instant, context-aware answers.',
    category:    'ai',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'ai_categorization',
    label:       'AI Transaction Categorization',
    description: 'Automatically categorize transactions using ML — learns your business over time.',
    category:    'ai',
    tiers:       ['standard', 'pro', 'enterprise'],
  },

  // ── Bookkeeping ───────────────────────────────────────────────────────
  {
    key:         'chart_of_accounts',
    label:       'Chart of Accounts',
    description: 'Full customizable chart of accounts seeded for your entity type.',
    category:    'bookkeeping',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'bank_feeds',
    label:       'Bank Feeds (Plaid)',
    description: 'Connect bank and credit card accounts via Plaid for automatic transaction import.',
    category:    'bookkeeping',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'reconciliation',
    label:       'Bank Reconciliation',
    description: 'Match imported transactions to ledger entries with one-click reconciliation.',
    category:    'bookkeeping',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'journal_entries',
    label:       'Manual Journal Entries',
    description: 'Post manual adjusting entries with full audit trail.',
    category:    'bookkeeping',
    tiers:       ['standard', 'pro', 'enterprise'],
  },

  // ── Formation ─────────────────────────────────────────────────────────
  {
    key:         'entity_determination',
    label:       'AI Entity Determination',
    description: 'AI questionnaire scores your situation and recommends the optimal entity type.',
    category:    'formation',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'ein_guidance',
    label:       'EIN Application Guidance',
    description: 'Pre-filled SS-4 walkthrough with IRS direct-link for online EIN application.',
    category:    'formation',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'state_registration',
    label:       'State Registration Wizard',
    description: 'Step-by-step state filing guide with fees, timelines, and portal links per state.',
    category:    'formation',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'compliance_calendar',
    label:       'Compliance Calendar',
    description: 'Auto-generated compliance deadlines — annual reports, BOI, tax filings — with reminders.',
    category:    'formation',
    tiers:       ['standard', 'pro', 'enterprise'],
  },
  {
    key:         'bookkeeping_handoff',
    label:       'Auto Bookkeeping Handoff',
    description: 'Formation completion automatically seeds your Chart of Accounts for zero-setup bookkeeping.',
    category:    'formation',
    tiers:       ['standard', 'pro', 'enterprise'],
  },

  // ── Payroll ───────────────────────────────────────────────────────────
  {
    key:         'payroll_runs',
    label:       'Payroll Runs',
    description: 'Full payroll processing with direct deposit, tax withholding, and journal sync.',
    category:    'payroll',
    tiers:       ['pro', 'enterprise'],
    comingSoon:  true,
  },
  {
    key:         'w4_1099',
    label:       'W-4 & 1099 Management',
    description: 'Collect W-4s from employees and generate 1099s for contractors at year-end.',
    category:    'payroll',
    tiers:       ['pro', 'enterprise'],
    comingSoon:  true,
  },

  // ── Collaboration ─────────────────────────────────────────────────────
  {
    key:         'single_user',
    label:       'Single User',
    description: 'One seat included.',
    category:    'collaboration',
    tiers:       ['lite'],
  },
  {
    key:         'team_3',
    label:       'Up to 3 Users',
    description: 'Invite your team or accountant.',
    category:    'collaboration',
    tiers:       ['standard'],
  },
  {
    key:         'unlimited_users',
    label:       'Unlimited Users',
    description: 'No seat limits — add your entire team and client roster.',
    category:    'collaboration',
    tiers:       ['pro', 'enterprise'],
  },
  {
    key:         'white_label',
    label:       'White-Label Branding',
    description: 'Replace InsightHunter branding with your firm name, logo, and colors.',
    category:    'collaboration',
    tiers:       ['pro', 'enterprise'],
  },

  // ── Integrations ──────────────────────────────────────────────────────
  {
    key:         'quickbooks_sync',
    label:       'QuickBooks Sync',
    description: 'Two-way sync with QuickBooks Online via OAuth — transactions, COA, and reports.',
    category:    'integrations',
    tiers:       ['standard', 'pro', 'enterprise'],
    comingSoon:  true,
  },
  {
    key:         'xero_sync',
    label:       'Xero Integration',
    description: 'Connect Xero as your ledger source — full read/write via Xero API.',
    category:    'integrations',
    tiers:       ['pro', 'enterprise'],
    comingSoon:  true,
  },
  {
    key:         'plaid',
    label:       'Plaid Bank Feeds',
    description: 'Connect 12,000+ US financial institutions for live transaction feeds.',
    category:    'integrations',
    tiers:       ['standard', 'pro', 'enterprise'],
  },

  // ── Platform ──────────────────────────────────────────────────────────
  {
    key:         'pwa',
    label:       'Progressive Web App',
    description: 'Install InsightHunter on any device — offline-capable, app-like experience.',
    category:    'platform',
    tiers:       ['lite', 'standard', 'pro', 'enterprise'],
  },
  {
    key:         'sla',
    label:       'SLA & Uptime Guarantee',
    description: '99.99% uptime SLA backed by Cloudflare's global network.',
    category:    'platform',
    tiers:       ['enterprise'],
  },
  {
    key:         'dedicated_onboarding',
    label:       'Dedicated Onboarding',
    description: 'White-glove setup call with the InsightHunter team.',
    category:    'platform',
    tiers:       ['enterprise'],
  },
];

// ── Helpers ───────────────────────────────────────────────────────────────
export function getFeaturesByTier(tier: Tier): Feature[] {
  return FEATURES.filter(f => f.tiers.includes(tier));
}

export function getFeaturesByCategory(category: FeatureCategory): Feature[] {
  return FEATURES.filter(f => f.category === category);
}

export function tierHasFeature(tier: Tier, key: string): boolean {
  const feature = FEATURES.find(f => f.key === key);
  return feature?.tiers.includes(tier) ?? false;
}
