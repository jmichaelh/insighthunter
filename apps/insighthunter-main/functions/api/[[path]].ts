import type { EventContext } from '@cloudflare/workers-types';

interface Env {
  AUTH_WORKER:        Fetcher;
  BOOKKEEPING_WORKER: Fetcher;
  AGENTS_WORKER:      Fetcher;
  BIZFORMA_WORKER:    Fetcher;
  LITE_WORKER:        Fetcher;
}

const WORKER_MAP: Record<string, keyof Env> = {
  'auth':        'AUTH_WORKER',
  'dashboard':   'AGENTS_WORKER',
  'insights':    'AGENTS_WORKER',
  'reports':     'AGENTS_WORKER',
  'forecast':    'AGENTS_WORKER',
  'bookkeeping': 'BOOKKEEPING_WORKER',
  'formations':  'BIZFORMA_WORKER',
  'ein':         'BIZFORMA_WORKER',
  'state-registration': 'BIZFORMA_WORKER',
  'tax-accounts':       'BIZFORMA_WORKER',
  'compliance':         'BIZFORMA_WORKER',
  'documents':          'BIZFORMA_WORKER',
  'entity-determination': 'BIZFORMA_WORKER',
  'lite':        'LITE_WORKER',
  'analytics':   'AGENTS_WORKER',
};

export async function onRequest(
  ctx: EventContext<Env, string, Record<string, unknown>>
): Promise<Response> {
  const url      = new URL(ctx.request.url);
  // Strip /api/ prefix → get first path segment
  const segments = url.pathname.replace(/^\/api\//, '').split('/');
  const prefix   = segments[0];

  const workerKey = WORKER_MAP[prefix];
  if (!workerKey) {
    return new Response(JSON.stringify({ error: `Unknown API route: ${prefix}` }), {
      status:  404,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const worker        = ctx.env[workerKey];
  // Rewrite URL to worker's internal path
  const internalUrl   = new URL(ctx.request.url);
  internalUrl.pathname = `/api/${segments.join('/')}`;

  return worker.fetch(new Request(internalUrl.toString(), ctx.request));
}
