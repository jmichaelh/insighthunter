import type { AppFeature } from '$lib/types';

export const features: AppFeature[] = [
  {
    slug: 'bookkeeping',
    name: 'Smart Bookkeeping',
    tagline: 'Automated books. Zero headaches.',
    icon: '📒',
    tier: 'Standard+',
    description: 'Upload your bank CSV or connect your account and watch InsightHunter categorize transactions, reconcile accounts, and keep your books clean — automatically.',
    features: [
      'Automated transaction categorization',
      'Chart of Accounts management',
      'Bank reconciliation',
      'Multi-currency support',
      'Recurring transaction rules',
      'Audit trail'
    ],
    benefits: [
      'Save 5+ hours per week on manual entry',
      'Eliminate month-end close stress',
      'Always audit-ready'
    ]
  },
  {
    slug: 'bizforma',
    name: 'BizForma',
    tagline: 'Form your business in minutes, not months.',
    icon: '🏢',
    tier: 'Add-on $99',
    description: 'AI-guided wizard walks you through entity selection, EIN application, state registration, and tax account setup — from sole prop to LLC to S-Corp.',
    features: [
      'AI entity type recommendation',
      'EIN application pre-fill (SS-4)',
      'State-by-state filing guidance',
      'EFTPS + state tax account setup',
      'Compliance calendar & reminders',
      'Document storage (R2)'
    ],
    benefits: [
      'Avoid costly formation mistakes',
      'Know exactly what filings are due and when',
      'Formation-to-bookkeeping handoff in one click'
    ]
  },
  {
    slug: 'insight-lite',
    name: 'Insight Lite',
    tagline: 'Your first financial dashboard. Free forever.',
    icon: '💡',
    tier: 'Free',
    description: 'Get instant clarity on your revenue, expenses, and cash position without spending a dime. Perfect for freelancers and solopreneurs.',
    features: [
      'Basic P&L dashboard',
      '3 reports/month',
      'CSV upload (500 rows)',
      'Revenue vs. expense summary',
      'Month-over-month comparison',
      'Community access'
    ],
    benefits: [
      'Free forever — no credit card needed',
      'Up and running in under 5 minutes',
      'Upgrade anytime without losing data'
    ]
  },
  {
    slug: 'insight-standard',
    name: 'Insight Standard',
    tagline: 'Full financial clarity at a fraction of CFO cost.',
    icon: '📊',
    tier: 'Standard ($49/mo)',
    description: 'Everything a growing business needs: complete P&L, cash flow statements, rolling forecasts, and KPI alerts that keep you ahead of problems.',
    features: [
      'Full P&L + Cash Flow reports',
      'Unlimited reports & exports',
      '3-month cash flow forecast',
      'KPI alerts & benchmarks',
      'Bookkeeping module',
      'PDF export for stakeholders'
    ],
    benefits: [
      'Replace a $3,000/month fractional CFO for $49',
      'Catch cash flow crunches before they happen',
      'Impress investors and lenders with clean reports'
    ]
  },
  {
    slug: 'insight-pro',
    name: 'Insight Pro',
    tagline: 'Your AI CFO, working 24/7.',
    icon: '🤖',
    tier: 'Pro ($199/mo)',
    description: 'The full Auto-CFO suite. AI-powered recommendations, 12-month forecasting, white-label client reports, and everything you need to run the financial side of your business.',
    features: [
      'AI CFO insights & action items',
      '12-month cash flow forecast',
      'Scenario planning (best/worst/base)',
      'White-label client reports',
      'Multi-user access (3 seats)',
      'QuickBooks + Xero sync (coming Q2 2026)'
    ],
    benefits: [
      'Get CFO-quality advice on demand',
      'Present polished reports to any stakeholder',
      'Manage multiple client entities'
    ]
  },
  {
    slug: 'scout',
    name: 'Scout AI',
    tagline: 'Spot trends before your competitors do.',
    icon: '🔍',
    tier: 'Pro',
    description: 'Scout continuously analyzes your financial data, compares it to industry benchmarks, and surfaces anomalies, opportunities, and risks — before they become problems.',
    features: [
      'Anomaly detection',
      'Industry benchmark comparisons',
      'Revenue trend analysis',
      'Expense pattern alerts',
      'Cash flow risk scoring',
      'Weekly AI digest email'
    ],
    benefits: [
      'Never be blindsided by a bad month again',
      'Know where you stand vs. your industry',
      'Actionable alerts, not noise'
    ]
  },
  {
    slug: 'pbx',
    name: 'Business PBX',
    tagline: 'A professional phone system for $29/month.',
    icon: '📞',
    tier: 'Add-on $29/mo',
    description: 'Virtual PBX with IVR menus, call routing, voicemail transcription, and toll-free numbers. Looks enterprise, costs nothing like it.',
    features: [
      'Virtual phone numbers (local + toll-free)',
      'IVR auto-attendant',
      'Call routing & forwarding',
      'Voicemail-to-email transcription',
      'Call recording',
      'Team extensions'
    ],
    benefits: [
      'Sound like a Fortune 500 from day one',
      'Never miss a business call',
      'Works on any device — no hardware needed'
    ]
  },
  {
    slug: 'payroll',
    name: 'Payroll',
    tagline: 'Pay your people. File your taxes. Automatically.',
    icon: '💰',
    tier: 'Add-on $39/mo',
    description: 'Full-service payroll that calculates, withholds, and files federal + state payroll taxes automatically. Direct deposit included.',
    features: [
      'Automated payroll runs',
      'Federal + state tax filings',
      'W-2 and 1099 generation',
      'Direct deposit',
      'Employee self-service portal',
      'Payroll-to-bookkeeping sync'
    ],
    benefits: [
      'Avoid IRS payroll penalties',
      'Save hours of manual calculations',
      'Payroll syncs directly to your P&L'
    ]
  },
  {
    slug: 'website-services',
    name: 'Website Services',
    tagline: 'A beautiful website that works as hard as you do.',
    icon: '🌐',
    tier: 'Add-on $149 setup + $29/mo',
    description: 'Professionally designed, SEO-optimized business websites built on Cloudflare Pages — lightning fast, globally distributed, and fully managed.',
    features: [
      'Custom design (3 revision rounds)',
      'Mobile-first responsive layout',
      'On-page SEO optimization',
      'Contact forms & lead capture',
      'Cloudflare Pages hosting (global CDN)',
      'Monthly content updates included'
    ],
    benefits: [
      'No technical skills required',
      'Faster than 99% of competitor sites',
      'Generates leads while you sleep'
    ]
  }
];
