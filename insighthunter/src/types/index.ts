
export interface AppDefinition {
  id: string;
  name: string;
  image: string;
  description: string;
  href: string;
  tags: string[];
  category: "Financial" | "Marketing" | "HR";
}

export interface PricingPlan {
  id: string;
  name: string;
  slug: string;
  price: number;
  annualPrice?: number;
  oneTime?: boolean;
  description: string;
  stripePriceId: string;
  stripeAnnualPriceId?: string;
  tier: string;
  highlight?: boolean;
  badge?: string;
  cta: string;
  features: string[];
  notIncluded?: string[];
}

export interface Addon {
  id: string;
  name: string;
  description: string;
  price: number;
  interval: "one-time" | "monthly";
  stripePriceId: string;
}

export interface CartItem {
  id: string;
  name: string;
  price: number;
  interval: string;
  type: "plan" | "addon";
  quantity: number;
  stripePriceId: string;
}

export interface Cart {
  items: CartItem[];
  total: number;
}

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  tier: "lite" | "standard" | "pro";
  orgId: string;
  avatarUrl?: string;
}

export interface Session {
  token: string;
  user: AuthUser;
}

export interface ApiResponse<T = unknown> {
  ok: boolean;
  data?: T;
  error?: string;
  _debug?: unknown;
}

export interface KPISnapshot {
  revenue: number;
  expenses: number;
  netIncome: number;
  cashBalance: number;
  grossMargin: number;
  period: string;
  asOf: string;
}

export interface DashboardData {
  kpis: KPISnapshot;
  recentAlerts: Alert[];
  trendData: TrendPoint[];
}

export interface TrendPoint {
  period: string;
  revenue: number;
  expenses: number;
  net: number;
}

export interface Alert {
  id: string;
  type: "cash_low" | "expense_spike" | "revenue_drop" | "insight";
  message: string;
  severity: "info" | "warning" | "critical";
  createdAt: string;
}

export interface ProfitLoss {
  periodStart: string;
  periodEnd: string;
  totalRevenue: number;
  totalExpenses: number;
  netIncome: number;
  grossMargin: number;
  rows: PLRow[];
}

export interface PLRow {
  account: string;
  amount: number;
  type: "income" | "expense";
  category: string;
}

export interface ReportRecord {
  id: string;
  orgId: string;
  type: "pl" | "cashflow" | "balance_sheet" | "forecast";
  title: string;
  periodStart: string;
  periodEnd: string;
  r2Key: string;
  createdAt: string;
  createdBy: string;
}

export interface ForecastResult {
  periods: ForecastPeriod[];
  confidence: number;
  generatedAt: string;
  modelVersion: string;
}

export interface ForecastPeriod {
  period: string;
  projectedRev: number;
  projectedExp: number;
  projectedNet: number;
  lower: number;
  upper: number;
}

export interface Transaction {
  id: string;
  orgId: string;
  date: string;
  description: string;
  amount: number;
  category: string;
  account: string;
  source: "qbo" | "csv" | "manual";
  createdAt: string;
}

export interface Client {
  id: string;
  orgId: string;
  name: string;
  email: string;
  tier: "lite" | "standard" | "enterprise";
  status: "active" | "suspended" | "trial";
  createdAt: string;
}

export interface Insight {
  id: string;
  orgId: string;
  summary: string;
  detail: string;
  actions: string[];
  model: string;
  createdAt: string;
}

export interface TokenPayload {
  sub: string;
  email: string;
  name: string;
  tier: string;
  orgId: string;
  iat: number;
  exp: number;
}
