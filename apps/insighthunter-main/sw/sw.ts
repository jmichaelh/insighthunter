/// <reference lib="webworker" />

// ════════════════════════════════════════════════════════════════════════
// InsightHunter — Service Worker
// src/sw.ts
//
// Strategies:
//   Shell / static assets  → Cache-first, versioned
//   API GET (safe routes)  → Network-first, 5s timeout, stale fallback
//   API mutations          → Network-only + Background Sync queue
//   Navigation             → Network-first → SPA shell fallback → /offline
// ════════════════════════════════════════════════════════════════════════

declare const self: ServiceWorkerGlobalScope;

// ── Version & cache names ──────────────────────────────────────────────
const SW_VERSION     = 'v1.4.0';
const CACHE_SHELL    = `ih-shell-${SW_VERSION}`;
const CACHE_STATIC   = `ih-static-${SW_VERSION}`;
const CACHE_API      = `ih-api-${SW_VERSION}`;
const CACHE_PAGES    = `ih-pages-${SW_VERSION}`;
const CACHE_SYNC_META = 'ih-sync-meta';

const ALL_CACHES = [CACHE_SHELL, CACHE_STATIC, CACHE_API, CACHE_PAGES];

// ── App shell — precached on install ──────────────────────────────────
const SHELL_URLS: string[] = [
  '/',
  '/dashboard',
  '/offline',
  '/auth/login',
  '/auth/register',
  '/manifest.webmanifest',
  '/favicon.svg',
  '/logo.svg',
];

// ── Static asset patterns — cache-first ───────────────────────────────
const STATIC_PATTERNS: RegExp[] = [
  /\/fonts\//,
  /\/icons\//,
  /\.woff2?$/,
  /\.ttf$/,
  /\.svg$/,
  /\/_astro\/.+\.(js|css)$/,
];

// ── API patterns safe to cache (GET only) ─────────────────────────────
const API_CACHEABLE_PATTERNS: RegExp[] = [
  /\/api\/v1\/dashboard\/kpi/,
  /\/api\/v1\/dashboard\/activity/,
  /\/api\/v1\/dashboard\/revenue-chart/,
  /\/api\/v1\/dashboard\/cash-flow-chart/,
  /\/api\/v1\/reports\/(pl|cash_flow|balance_sheet)/,
  /\/api\/v1\/insights/,
  /\/api\/v1\/forecast/,
  /\/api\/v1\/bookkeeping\/categories/,
  /\/api\/v1\/transactions\?/,
];

const API_CACHE_TTL_MS  = 5 * 60 * 1_000;   // 5 minutes
const NETWORK_TIMEOUT_MS = 5_000;            // 5 seconds

// ════════════════════════════════════════════════════════════════════════
// INSTALL
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('install', (event: ExtendableEvent) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_SHELL);
      await cache.addAll(SHELL_URLS);
      await self.skipWaiting();
      console.log(`[SW ${SW_VERSION}] Installed.`);
    })()
  );
});

// ════════════════════════════════════════════════════════════════════════
// ACTIVATE — prune stale caches
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('activate', (event: ExtendableEvent) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter(k => !ALL_CACHES.includes(k) && k !== CACHE_SYNC_META)
          .map(k => {
            console.log(`[SW] Deleting old cache: ${k}`);
            return caches.delete(k);
          })
      );
      await self.clients.claim();
      console.log(`[SW ${SW_VERSION}] Activated.`);
    })()
  );
});

// ════════════════════════════════════════════════════════════════════════
// FETCH — routing
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('fetch', (event: FetchEvent) => {
  const { request } = event;
  const url          = new URL(request.url);

  // Only handle same-origin http(s)
  if (!url.protocol.startsWith('http')) return;
  if (url.hostname !== self.location.hostname) return;

  // Mutations → Background Sync queue
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method)) {
    event.respondWith(handleMutation(request));
    return;
  }

  // Static assets → cache-first
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request, CACHE_STATIC));
    return;
  }

  // Cacheable API → network-first with TTL stale fallback
  if (isCacheableAPI(url.pathname)) {
    event.respondWith(networkFirstAPI(request));
    return;
  }

  // Other API routes → network-only
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkOnly(request));
    return;
  }

  // Auth pages → network-first, no stale fallback
  if (url.pathname.startsWith('/auth/')) {
    event.respondWith(networkFirst(request, CACHE_PAGES, false));
    return;
  }

  // Navigation → network-first → SPA shell fallback
  if (request.mode === 'navigate') {
    event.respondWith(handleNavigation(request));
    return;
  }

  // Default → network-first
  event.respondWith(networkFirst(request, CACHE_PAGES));
});

// ════════════════════════════════════════════════════════════════════════
// STRATEGIES
// ════════════════════════════════════════════════════════════════════════

/** Cache-first: serve cached, fetch + store on miss. */
async function cacheFirst(
  request:   Request,
  cacheName: string,
): Promise<Response> {
  const cached = await caches.match(request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) {
      const c = await caches.open(cacheName);
      c.put(request, response.clone());
    }
    return response;
  } catch {
    return offlineFallback(request);
  }
}

/** Network-first: try network, fall back to cache on failure/timeout. */
async function networkFirst(
  request:       Request,
  cacheName:     string,
  useCacheOnFail = true,
): Promise<Response> {
  try {
    const response = await fetchWithTimeout(request, NETWORK_TIMEOUT_MS);
    if (response.ok) {
      const c = await caches.open(cacheName);
      c.put(request, response.clone());
    }
    return response;
  } catch {
    if (useCacheOnFail) {
      const cached = await caches.match(request);
      if (cached) return cached;
    }
    return offlineFallback(request);
  }
}

/** Network-first for API: stamps TTL, serves stale on failure. */
async function networkFirstAPI(request: Request): Promise<Response> {
  const cache = await caches.open(CACHE_API);

  try {
    const response = await fetchWithTimeout(request, NETWORK_TIMEOUT_MS);

    if (response.ok) {
      cache.put(request, stampCacheTime(response.clone()));
      return response;
    }

    // Non-OK (e.g. 500) — serve stale if available
    const stale = await cache.match(request);
    return stale ?? response;

  } catch {
    const stale = await cache.match(request);
    if (stale && !isCacheExpired(stale, API_CACHE_TTL_MS)) {
      return stale;
    }
    return apiOfflineResponse(request.url);
  }
}

/** Network-only: no caching whatsoever. */
async function networkOnly(request: Request): Promise<Response> {
  try {
    return await fetch(request);
  } catch {
    return apiOfflineResponse(request.url);
  }
}

/** Navigation: network → exact cache → SPA shell → /offline page. */
async function handleNavigation(request: Request): Promise<Response> {
  try {
    const response = await fetchWithTimeout(request, NETWORK_TIMEOUT_MS);
    if (response.ok) {
      const c = await caches.open(CACHE_PAGES);
      c.put(request, response.clone());
    }
    return response;
  } catch {
    const exact = await caches.match(request);
    if (exact) return exact;

    const url = new URL(request.url);
    if (url.pathname.startsWith('/dashboard')) {
      const shell = await caches.match('/dashboard');
      if (shell) return shell;
    }

    const offline = await caches.match('/offline');
    if (offline) return offline;

    return new Response(
      `<!DOCTYPE html><html><body>
        <h1>You're offline</h1>
        <p>Reconnect to access InsightHunter.</p>
      </body></html>`,
      { status: 503, headers: { 'Content-Type': 'text/html' } }
    );
  }
}

/** Mutation handler: try network, queue for sync on failure. */
async function handleMutation(request: Request): Promise<Response> {
  try {
    return await fetch(request.clone());
  } catch {
    await queueRequest(request.clone());

    const reg = self.registration as any;
    if ('sync' in reg) {
      try { await reg.sync.register('ih-mutation-sync'); } catch { /* no sync API */ }
    }

    return new Response(
      JSON.stringify({
        queued:  true,
        error:   'You are offline. Request queued — will sync on reconnect.',
      }),
      { status: 202, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// BACKGROUND SYNC
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('sync', (event: SyncEvent) => {
  if (event.tag === 'ih-mutation-sync') {
    event.waitUntil(flushSyncQueue());
  }
});

interface QueuedRequest {
  id:        string;
  url:       string;
  method:    string;
  headers:   Record<string, string>;
  body:      string | null;
  timestamp: number;
}

async function queueRequest(request: Request): Promise<void> {
  const queue  = await getSyncQueue();
  const entry: QueuedRequest = {
    id:        crypto.randomUUID(),
    url:       request.url,
    method:    request.method,
    headers:   Object.fromEntries(request.headers.entries()),
    body:      ['GET', 'HEAD'].includes(request.method) ? null : await request.text(),
    timestamp: Date.now(),
  };
  queue.push(entry);
  await setSyncQueue(queue);
  console.log(`[SW] Queued: ${request.method} ${request.url}`);
}

async function flushSyncQueue(): Promise<void> {
  const queue = await getSyncQueue();
  if (!queue.length) return;

  console.log(`[SW] Flushing ${queue.length} queued request(s)…`);

  const failed: QueuedRequest[] = [];

  for (const entry of queue) {
    try {
      const res = await fetch(entry.url, {
        method:  entry.method,
        headers: entry.headers,
        body:    entry.body ?? undefined,
      });

      if (!res.ok && res.status >= 500) {
        failed.push(entry);
      } else {
        await broadcastMessage({ type: 'SYNC_COMPLETE', id: entry.id, url: entry.url, method: entry.method });
      }
    } catch {
      failed.push(entry);
    }
  }

  await setSyncQueue(failed);

  if (!failed.length) {
    console.log('[SW] Sync queue fully flushed.');
    await broadcastMessage({ type: 'SYNC_ALL_COMPLETE' });
  } else {
    console.warn(`[SW] ${failed.length} request(s) remain in queue.`);
  }
}

// Persist sync queue as JSON blob inside a dedicated cache
const SYNC_QUEUE_URL = 'https://ih-internal/sync-queue';

async function getSyncQueue(): Promise<QueuedRequest[]> {
  try {
    const cache = await caches.open(CACHE_SYNC_META);
    const res   = await cache.match(SYNC_QUEUE_URL);
    if (!res) return [];
    return await res.json() as QueuedRequest[];
  } catch { return []; }
}

async function setSyncQueue(queue: QueuedRequest[]): Promise<void> {
  const cache = await caches.open(CACHE_SYNC_META);
  await cache.put(
    SYNC_QUEUE_URL,
    new Response(JSON.stringify(queue), {
      headers: { 'Content-Type': 'application/json' },
    })
  );
}

// ════════════════════════════════════════════════════════════════════════
// PUSH NOTIFICATIONS
// ════════════════════════════════════════════════════════════════════════
interface PushPayload {
  title:   string;
  body:    string;
  type:    'info' | 'warning' | 'insight' | 'alert' | 'report_ready';
  href?:   string;
  icon?:   string;
  orgId?:  string;
  data?:   Record<string, unknown>;
}

self.addEventListener('push', (event: PushEvent) => {
  if (!event.data) return;

  let payload: PushPayload;
  try {
    payload = event.data.json() as PushPayload;
  } catch {
    payload = { title: 'InsightHunter', body: event.data.text(), type: 'info' };
  }

  const ICONS: Record<PushPayload['type'], string> = {
    info:         '/icons/notif-info.png',
    warning:      '/icons/notif-warning.png',
    insight:      '/icons/notif-insight.png',
    alert:        '/icons/notif-alert.png',
    report_ready: '/icons/notif-report.png',
  };

  const ACTIONS: Record<PushPayload['type'], NotificationAction[]> = {
    info:         [],
    warning:      [{ action: 'view',     title: 'View Details'  }],
    insight:      [{ action: 'view',     title: 'See Insight'   }, { action: 'dismiss', title: 'Dismiss' }],
    alert:        [{ action: 'view',     title: 'Fix Now'       }],
    report_ready: [{ action: 'download', title: 'Download PDF'  }, { action: 'view', title: 'View Report' }],
  };

  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body:     payload.body,
      icon:     payload.icon ?? ICONS[payload.type],
      badge:    '/icons/badge-96.png',
      vibrate:  payload.type === 'alert' ? [200, 100, 200] : [100],
      tag:      `ih-${payload.type}`,
      renotify: payload.type === 'alert',
      actions:  ACTIONS[payload.type],
       {
        href:  payload.href ?? '/dashboard',
        type:  payload.type,
        orgId: payload.orgId,
        ...payload.data,
      },
    })
  );
});

self.addEventListener('notificationclick', (event: NotificationEvent) => {
  event.notification.close();

  const { href, type } = event.notification.data as { href: string; type: string };
  const targetUrl = event.action === 'download' && type === 'report_ready'
    ? `${href}?action=download`
    : href;

  event.waitUntil(
    (async () => {
      const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });

      for (const client of clients) {
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          client.postMessage({ type: 'NOTIFICATION_CLICK', href: targetUrl });
          return client.focus();
        }
      }

      return self.clients.openWindow(targetUrl);
    })()
  );
});

self.addEventListener('pushsubscriptionchange', (event: Event) => {
  const e = event as any;
  e.waitUntil(
    (async () => {
      try {
        const subscription = await self.registration.pushManager.subscribe(
          e.oldSubscription?.options ?? { userVisibleOnly: true }
        );
        await fetch('/api/v1/notifications/subscription', {
          method:  'PUT',
          headers: { 'Content-Type': 'application/json' },
          body:    JSON.stringify({ subscription }),
        });
      } catch (err) {
        console.error('[SW] Failed to renew push subscription:', err);
      }
    })()
  );
});

// ════════════════════════════════════════════════════════════════════════
// MESSAGE HANDLER (app → SW)
// ════════════════════════════════════════════════════════════════════════
self.addEventListener('message', (event: ExtendableMessageEvent) => {
  const { type, payload } = (event.data ?? {}) as { type: string; payload?: unknown };

  switch (type) {

    case 'SKIP_WAITING':
      self.skipWaiting();
      break;

    case 'CLEAR_API_CACHE':
      event.waitUntil(caches.delete(CACHE_API));
      break;

    case 'CLEAR_ALL_CACHES':
      event.waitUntil(Promise.all(ALL_CACHES.map(c => caches.delete(c))));
      break;

    case 'GET_VERSION':
      event.source?.postMessage({ type: 'SW_VERSION', version: SW_VERSION });
      break;

    case 'GET_QUEUE_LENGTH':
      event.waitUntil(
        getSyncQueue().then(q =>
          event.source?.postMessage({ type: 'QUEUE_LENGTH', length: q.length })
        )
      );
      break;

    case 'FORCE_SYNC':
      event.waitUntil(flushSyncQueue());
      break;

    case 'PRECACHE_URLS':
      if (Array.isArray(payload)) {
        event.waitUntil(
          caches.open(CACHE_PAGES).then(c => c.addAll(payload as string[]))
        );
      }
      break;

    default:
      break;
  }
});

// ════════════════════════════════════════════════════════════════════════
// UTILITIES
// ════════════════════════════════════════════════════════════════════════

function isStaticAsset(pathname: string): boolean {
  return STATIC_PATTERNS.some(re => re.test(pathname));
}

function isCacheableAPI(pathname: string): boolean {
  return API_CACHEABLE_PATTERNS.some(re => re.test(pathname));
}

async function fetchWithTimeout(
  request:   RequestInfo,
  ms:        number,
): Promise<Response> {
  const controller = new AbortController();
  const timer      = setTimeout(() => controller.abort(), ms);
  try {
    return await fetch(
      typeof request === 'string'
        ? new Request(request, { signal: controller.signal })
        : new Request(request, { signal: controller.signal })
    );
  } finally {
    clearTimeout(timer);
  }
}

function stampCacheTime(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set('x-sw-cached-at', String(Date.now()));
  return new Response(response.body, {
    status:     response.status,
    statusText: response.statusText,
    headers,
  });
}

function isCacheExpired(response: Response, ttlMs: number): boolean {
  const at = response.headers.get('x-sw-cached-at');
  if (!at) return false;
  return Date.now() - Number(at) > ttlMs;
}

async function offlineFallback(request: Request): Promise<Response> {
  const accepts = request.headers.get('accept') ?? '';
  if (accepts.includes('text/html')) {
    const page = await caches.match('/offline');
    if (page) return page;
    return new Response(
      `<!DOCTYPE html><html><body>
        <h1>You're offline</h1>
        <p>Please reconnect to use InsightHunter.</p>
      </body></html>`,
      { status: 503, headers: { 'Content-Type': 'text/html' } }
    );
  }
  return apiOfflineResponse(request.url);
}

function apiOfflineResponse(url: string): Response {
  return new Response(
    JSON.stringify({ error: 'You are offline.', offline: true, url }),
    { status: 503, headers: { 'Content-Type': 'application/json' } }
  );
}

async function broadcastMessage( Record<string, unknown>): Promise<void> {
  const clients = await self.clients.matchAll({ type: 'window' });
  for (const client of clients) client.postMessage(data);
}
