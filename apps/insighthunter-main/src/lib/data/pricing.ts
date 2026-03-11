import type { PricingPlan, Addon } from '$lib/types';

export const plans: PricingPlan[] = [
  {
    id: 'free',
    tier: 'free',
    name: 'Insight Lite',
    price: 0,
    interval: 'month',
    description: 'Perfect for freelancers just starting out.',
    cta: 'Get Started Free',
    features: [
      '1 user',
      'Basic P&L dashboard',
      '3 reports per month',
      'CSV upload (up to 500 rows)',
      'Email support',
      'Community access'
    ]
  },
  {
    id: 'standard',
    tier: 'standard',
    name: 'Insight Standard',
    price: 49,
    interval: 'month',
    stripePriceId: 'price_standard_monthly',
    description: 'For growing freelancers who need deeper analysis.',
    cta: 'Start Free Trial',
    features: [
      '1 user',
      'Full P&L + Cash Flow reports',
      'Unlimited reports',
      'Cash flow forecasting (3 months)',
      'KPI alerts & benchmarks',
      'Bookkeeping module',
      'Exportable PDFs',
      'Priority email support'
    ]
  },
  {
    id: 'pro',
    tier: 'pro',
    name: 'Insight Pro',
    price: 199,
    interval: 'month',
    stripePriceId: 'price_pro_monthly',
    description: 'The full Auto-CFO suite for serious businesses.',
    highlighted: true,
    badge: 'Most Popular',
    cta: 'Start Free Trial',
    features: [
      '3 users',
      'Everything in Standard',
      'AI CFO insights & recommendations',
      '12-month cash flow forecast',
      'BizForma business formation',
      'Scout AI trend analysis',
      'White-label client reports',
      'QuickBooks & Xero sync (Q2 2026)',
      'Phone + chat support',
      'Dedicated onboarding'
    ]
  },
  {
    id: 'enterprise',
    tier: 'enterprise',
    name: 'White Label',
    price: 0,
    interval: 'custom',
    description: 'For fractional CFO firms managing multiple clients.',
    cta: 'Contact Sales',
    features: [
      'Unlimited users & clients',
      'Full white-label branding',
      'Custom subdomain',
      'API access',
      'Dedicated account manager',
      'Custom integrations',
      'SLA guarantee',
      'Onsite training available'
    ]
  }
];

export const addons: Addon[] = [
  {
    id: 'bizforma',
    name: 'BizForma',
    price: 99,
    interval: 'one-time',
    description: 'AI-guided business formation, EIN, and state registration.',
    stripePriceId: 'price_bizforma_onetime'
  },
  {
    id: 'insight-report',
    name: 'One-Off Insight Report',
    price: 100,
    interval: 'one-time',
    description: 'A deep-dive financial analysis report for your business.',
    stripePriceId: 'price_report_onetime'
  },
  {
    id: 'pbx',
    name: 'Business PBX Phone',
    price: 29,
    interval: 'month',
    description: 'Virtual PBX phone system with IVR, voicemail, and call routing.',
    stripePriceId: 'price_pbx_monthly'
  },
  {
    id: 'payroll',
    name: 'Payroll Module',
    price: 39,
    interval: 'month',
    description: 'Automated payroll processing, tax filings, and direct deposit.',
    stripePriceId: 'price_payroll_monthly'
  },
  {
    id: 'website',
    name: 'Website Services',
    price: 29,
    interval: 'month',
    description: 'Managed business website — design, hosting, and SEO. $149 setup.',
    stripePriceId: 'price_website_monthly'
  }
];
