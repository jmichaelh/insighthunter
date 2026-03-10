export function trackPageView(path: string): void {
  if (typeof window === 'undefined') return;
  // Cloudflare Web Analytics (beacon is injected via MarketingLayout)
  if ((window as any).__cfBeacon) return;
  navigator.sendBeacon?.('/api/analytics/pageview', JSON.stringify({ path }));
}

export function trackEvent(event: string, props: Record<string, string | number> = {}): void {
  if (typeof window === 'undefined') return;
  navigator.sendBeacon?.('/api/analytics/event', JSON.stringify({ event, ...props }));
}
