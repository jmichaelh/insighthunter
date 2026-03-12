export interface FeatureItem {
  icon: string;
  title: string;
  description: string;
  tier: string;
}

export const HERO_FEATURES: FeatureItem[] = [
  {
    icon: '🤖',
    title: 'Auto-CFO Intelligence',
    description: 'AI analyzes your financials and delivers CFO-grade insights without hiring one.',
    tier: 'pro',
  },
  {
    icon: '📊',
    title: 'Real-Time Dashboards',
    description: 'P&L, cash flow, and KPI dashboards that update the moment you upload data.',
    tier: 'lite',
  },
  {
    icon: '🔮',
    title: '12-Month Forecasting',
    description: 'Predictive cash flow models built from your actual historical data.',
    tier: 'standard',
  },
  {
    icon: '📄',
    title: 'Exportable Reports',
    description: 'White-label PDFs ready for your clients, investors, or accountant.',
    tier: 'standard',
  },
  {
    icon: '🏢',
    title: 'Business Formation',
    description: 'BizForma guides you from entity selection to EIN to compliance calendar.',
    tier: 'pro',
  },
  {
    icon: '🔭',
    title: 'Market Intelligence',
    description: 'Scout surfaces competitor pricing, benchmarks, and growth opportunities.',
    tier: 'pro',
  },
  {
    icon: '📒',
    title: 'AI Bookkeeping',
    description: 'Auto-categorize transactions and maintain audit-ready records effortlessly.',
    tier: 'standard',
  },
  {
    icon: '⚡',
    title: 'Cloudflare-Powered',
    description: 'Sub-100ms global performance with enterprise-grade security — no extra cost.',
    tier: 'lite',
  },
];

export const TESTIMONIALS = [
  {
    name: 'Sarah Chen',
    role: 'Freelance Consultant',
    avatar: 'SC',
    quote: "InsightHunter replaced my 6-hour monthly spreadsheet ritual. I upload my CSV and have a full P&L in 30 seconds. It's absurdly good.",
    tier: 'standard',
    rating: 5,
  },
  {
    name: 'Marcus Webb',
    role: 'Fractional CFO',
    avatar: 'MW',
    quote: 'I manage 12 clients under my brand. The white-label reports look so professional my clients think I built a custom tool. InsightHunter Pro is worth every dollar.',
    tier: 'pro',
    rating: 5,
  },
  {
    name: 'Priya Nair',
    role: 'E-Commerce Owner',
    avatar: 'PN',
    quote: "The cash flow forecast caught a $40k shortfall 3 months out. I had time to act. That single insight paid for years of the subscription.",
    tier: 'standard',
    rating: 5,
  },
  {
    name: 'David Torres',
    role: 'Restaurant Group Owner',
    avatar: 'DT',
    quote: 'BizForma walked me through forming 3 LLCs in different states. The compliance calendar means I never miss a deadline anymore.',
    tier: 'pro',
    rating: 5,
  },
];
