export async function registerSW(): Promise<void> {
    if (typeof navigator === 'undefined' || !('serviceWorker' in navigator)) return;
    try {
      const reg = await navigator.serviceWorker.register('/sw.js', { scope: '/' });
      console.log('[SW] registered', reg.scope);
    } catch (err) {
      console.warn('[SW] registration failed', err);
    }
  }
  