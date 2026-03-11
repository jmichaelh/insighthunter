// Registers SW and wires up lifecycle events for the dashboard.

export async function registerSW(): Promise<void> {
    if (!('serviceWorker' in navigator)) return;
  
    try {
      const reg = await navigator.serviceWorker.register('/sw.js', {
        scope: '/',
        type:  'classic',
      });
  
      console.log('[SW] Registered:', reg.scope);
  
      // Poll for updates every 60s while tab is visible
      setInterval(() => {
        if (document.visibilityState === 'visible') reg.update().catch(() => {});
      }, 60_000);
  
      // Detect new SW waiting — emit toast event
      reg.addEventListener('updatefound', () => {
        const next = reg.installing;
        if (!next) return;
        next.addEventListener('statechange', () => {
          if (next.state === 'installed' && navigator.serviceWorker.controller) {
            window.dispatchEvent(
              new CustomEvent('sw:update-available', { detail: { reg } })
            );
          }
        });
      });
  
      // Reload when new SW takes control
      let refreshing = false;
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (refreshing) return;
        refreshing = true;
        window.location.reload();
      });
  
      // Wire up SW → app messages
      navigator.serviceWorker.addEventListener('message', (event: MessageEvent) => {
        const { type, ...data } = event.data ?? {};
        switch (type) {
          case 'SYNC_COMPLETE':
          case 'SYNC_ALL_COMPLETE':
            // Dashboard components listen for this to trigger refetch
            window.dispatchEvent(new CustomEvent('sw:sync-complete', { detail: data }));
            break;
          case 'NOTIFICATION_CLICK':
            window.location.href = data.href;
            break;
          case 'SW_VERSION':
            console.log('[SW] Version:', data.version);
            break;
        }
      });
  
    } catch (err) {
      console.error('[SW] Registration failed:', err);
    }
  }
  
  export function skipWaiting(reg: ServiceWorkerRegistration): void {
    reg.waiting?.postMessage({ type: 'SKIP_WAITING' });
  }
  
  export function clearAPICache(): void {
    navigator.serviceWorker.controller?.postMessage({ type: 'CLEAR_API_CACHE' });
  }
  
  export function forceSWSync(): void {
    navigator.serviceWorker.controller?.postMessage({ type: 'FORCE_SYNC' });
  }
  
  export function getSWVersion(): void {
    navigator.serviceWorker.controller?.postMessage({ type: 'GET_VERSION' });
  }
  
  // Auto-register on import
  registerSW();
  