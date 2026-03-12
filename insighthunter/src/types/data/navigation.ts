export interface NavLink {
  label: string;
  href: string;
  children?: NavLink[];
}

export interface SidebarSection {
  label: string;
  items: SidebarItem[];
}

export interface SidebarItem {
  label: string;
  href: string;
  icon: string;
  badge?: string;
}

export const MARKETING_NAV: NavLink[] = [
  {
    label: 'Features',
    href: '/features',
    children: [
      { label: 'Insight Lite',      href: '/features/insight-lite' },
      { label: 'Insight Standard',  href: '/features/insight-standard' },
      { label: 'Insight Pro',       href: '/features/insight-pro' },
      { label: 'AI Bookkeeping',    href: '/features/bookkeeping' },
      { label: 'BizForma',          href: '/features/bizforma' },
      { label: 'Scout',             href: '/features/scout' },
      { label: 'PBX Phone',         href: '/features/pbx' },
      { label: 'Payroll',           href: '/features/payroll' },
      { label: 'Website Services',  href: '/features/website-services' },
    ],
  },
  { label: 'Pricing',  href: '/pricing' },
  { label: 'About',    href: '/about' },
  { label: 'Support',  href: '/contact' },
];

export const DASHBOARD_NAV: SidebarSection[] = [
  {
    label: 'Overview',
    items: [
      { label: 'Dashboard',   href: '/dashboard',            icon: '🏠' },
      { label: 'Insights',    href: '/dashboard/insights',   icon: '🧠', badge: 'AI' },
      { label: 'Reports',     href: '/dashboard/reports',    icon: '📊' },
      { label: 'Forecast',    href: '/dashboard/forecast',   icon: '🔮' },
    ],
  },
  {
    label: 'Apps',
    items: [
      { label: 'Bookkeeping', href: '/dashboard/bookkeeping', icon: '📒' },
      { label: 'BizForma',    href: '/dashboard/bizforma',    icon: '🏢' },
    ],
  },
  {
    label: 'Account',
    items: [
      { label: 'Settings',    href: '/dashboard/settings',   icon: '⚙️' },
      { label: 'Upgrade',     href: '/dashboard/upgrade',    icon: '⚡' },
    ],
  },
];
