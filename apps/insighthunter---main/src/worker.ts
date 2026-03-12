// apps/insighthunter-main/src/worker.ts
// This is the edge entry point — runs before Astro handles anything.
// Responsibilities:
//   1. www → apex redirect
//   2. Security headers on every response
//   3. Auth-gate dashboard routes (redirect unauthenticated → /auth/login)
//   4. Track page views via Analytics Engine
//   5. Pass everything else to Astro (_worker.js / ASSETS)

/// <reference types="@cloudflare/workers-types" />

interface Env {
    ASSETS:        Fetcher;
    AUTH_WORKER:   Fetcher;
    AGENTS_WORKER: Fetcher;
    SESSIONS:      KVNamespace;
    EVENTS:        AnalyticsEngineDataset;
    APP_URL:       string;
    APP_ENV:       string;
  }
  
  // Routes that require an active session
  const PROTECTED_PREFIXES = [
    '/dashboard',
    '/account',
    '/admin',
  ];
  
  // Routes that authenticated users should not see
  const AUTH_ONLY_PREFIXES = [
    '/auth/login',
    '/auth/signup',
  ];
  
  // Security headers applied to every HTML response
  const SECURITY_HEADERS: Record<string, string> = {
    'X-Content-Type-Options':           'nosniff',
    'X-Frame-Options':                  'DENY',
    'X-XSS-Protection':                 '1; mode=block',
    'Referrer-Policy':                  'strict-origin-when-cross-origin',
    'Permissions-Policy':               'camera=(), microphone=(), geolocation=()',
    'Strict-Transport-Security':        'max-age=63072000; includeSubDomains; preload',
    'Content-Security-Policy':
      "default-src 'self'; " +
      "script-src 'self' 'unsafe-inline' https://js.stripe.com; " +
      "style-src 'self' 'unsafe-inline'; " +
      "img-src 'self' data: https:; " +
      "connect-src 'self' https://api.stripe.com https://insighthunter.app; " +
      "frame-src https://js.stripe.com https://hooks.stripe.com; " +
      "font-src 'self' data:; " +
      "object-src 'none'; " +
      "base-uri 'self';",
  };
  
  export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
      const url = new URL(request.url);
      const { pathname, hostname } = url;
  
      // ── 1. www → apex redirect (301 permanent) ──────────────────────────────
      if (hostname === 'www.insighthunter.app') {
        return Response.redirect(`https://insighthunter.app${pathname}${url.search}`, 301);
      }
  
      // ── 2. Auth-gate: check protected routes ────────────────────────────────
      const isProtected = PROTECTED_PREFIXES.some((p) => pathname.startsWith(p));
      const isAuthRoute  = AUTH_ONLY_PREFIXES.some((p) => pathname.startsWith(p));
  
      if (isProtected || isAuthRoute) {
        const token = getToken(request);
  
        if (isProtected && !token) {
          // No token → redirect to login with return path
          const loginUrl = new URL('/auth/login', env.APP_URL);
          loginUrl.searchParams.set('next', pathname);
          return Response.redirect(loginUrl.toString(), 302);
        }
  
        if (token) {
          // Validate token against auth worker session store
          const sessionData = await env.SESSIONS.get(`session:${token}`);
  
          if (isProtected && !sessionData) {
            // Stale/invalid token → clear cookie + redirect
            const loginUrl = new URL('/auth/login', env.APP_URL);
            loginUrl.searchParams.set('next', pathname);
            const res = Response.redirect(loginUrl.toString(), 302);
            clearAuthCookie(res);
            return res;
          }
  
          if (isAuthRoute && sessionData) {
            // Already logged in → redirect to dashboard
            return Response.redirect(`${env.APP_URL}/dashboard`, 302);
          }
  
          // Inject plan into request headers so Astro pages can read it
          if (sessionData) {
            const { plan, userId } = JSON.parse(sessionData);
            const modifiedRequest = new Request(request, {
              headers: new Headers({
                ...Object.fromEntries(request.headers.entries()),
                'X-IH-User-Id': userId,
                'X-IH-Plan':    plan,
              }),
            });
  
            const response = await env.ASSETS.fetch(modifiedRequest);
            return applySecurityHeaders(response);
          }
        }
      }
  
      // ── 3. Track page view (non-blocking, API routes excluded) ──────────────
      if (!pathname.startsWith('/api/') && request.method === 'GET') {
        const token  = getToken(request);
        const userId = token
          ? (await env.SESSIONS.get(`session:${token}`)
              .then((s) => (s ? JSON.parse(s).userId : 'anonymous'))
              .catch(() => 'anonymous'))
          : 'anonymous';
  
        // Non-blocking — don't await
        env.EVENTS.writeDataPoint({
          blobs:   [pathname, request.headers.get('CF-IPCountry') ?? 'XX', userId],
          doubles: [1],
          indexes: [userId],
        });
      }
  
      // ── 4. Pass to Astro (static assets or SSR pages) ───────────────────────
      const response = await env.ASSETS.fetch(request);
      return applySecurityHeaders(response);
    },
  } satisfies ExportedHandler<Env>;
  
  
  // ─── Helpers ──────────────────────────────────────────────────────────────────
  
  function getToken(request: Request): string | null {
    // Check Authorization header first (API calls from Svelte islands)
    const authHeader = request.headers.get('Authorization');
    if (authHeader?.startsWith('Bearer ')) return authHeader.slice(7);
  
    // Fall back to cookie (server-rendered page requests)
    const cookie = request.headers.get('Cookie') ?? '';
    const match  = cookie.match(/(?:^|;\s*)ih_token=([^;]+)/);
    return match ? decodeURIComponent(match[1]) : null;
  }
  
  function clearAuthCookie(response: Response): void {
    response.headers.set(
      'Set-Cookie',
      'ih_token=; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=0'
    );
  }
  
  function applySecurityHeaders(response: Response): Response {
    const contentType = response.headers.get('Content-Type') ?? '';
    const isHTML      = contentType.includes('text/html');
  
    // Only apply security headers to HTML responses — not assets/JSON
    if (!isHTML) return response;
  
    const newHeaders = new Headers(response.headers);
    for (const [key, value] of Object.entries(SECURITY_HEADERS)) {
      newHeaders.set(key, value);
    }
    return new Response(response.body, {
      status:     response.status,
      statusText: response.statusText,
      headers:    newHeaders,
    });
  }
  