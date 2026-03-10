export interface NavItem {
    label:    string;
    href:     string;
    icon:     string;
    tier?:    string;
    children?: NavItem[];
  }
  
  export const DASHBOARD_NAV: NavItem[] = [
    { label: 'Overview',    href: '/dashboard',             icon: '🏠' },
    { label: 'Reports',     href: '/dashboard/reports',     icon: '📊' },
    { label: 'Forecast',    href: '/dashboard/forecast',    icon: '📈' },
    { label: 'Bookkeeping', href: '/dashboard/bookkeeping', icon: '📒', tier: 'standard' },
    { label: 'BizForma',    href: '/dashboard/bizforma',    icon: '🏛️', tier: 'standard' },
    { label: 'Insights',    href: '/dashboard/insights',    icon: '🤖' },
    { label: 'Settings',    href: '/dashboard/settings',    icon: '⚙️' },
  ];
  
  export const MARKETING_NAV = [
    { label: 'Features', href: '/features' },
    { label: 'Pricing',  href: '/pricing'  },
    { label: 'About',    href: '/about'    },
  ];
  