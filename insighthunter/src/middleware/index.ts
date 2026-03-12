import { defineMiddleware } from 'astro:middleware';

const PROTECTED_PREFIXES = ['/dashboard'];
const AUTH_ONLY_ROUTES   = ['/auth/login', '/auth/register'];

export const onRequest = defineMiddleware(async ({ request, cookies, locals, redirect }, next) => {
  const url     = new URL(request.url);
  const path    = url.pathname;
  const token   = cookies.get('ih_session')?.value;

  // Inject platform env into locals for SSR pages
  // (Cloudflare adapter sets locals.runtime automatically)
  const env = (locals as { runtime?: { env: Record<string, unknown> } }).runtime?.env ?? {};
  (locals as Record<string, unknown>).env = env;

  const isProtected = PROTECTED_PREFIXES.some(p => path.startsWith(p));
  const isAuthPage  = AUTH_ONLY_ROUTES.includes(path);

  if (isProtected && !token) {
    return redirect(`/auth/login?next=${encodeURIComponent(path)}`);
  }

  // Verify token with KV
  if (isProtected && token) {
    try {
      const kv = env.SESSIONS as KVNamespace | undefined;
      if (kv) {
        const session = await kv.get(`session:${token}`, 'json') as { userId: string; expiresAt: number } | null;
        if (!session || session.expiresAt < Date.now()) {
          cookies.delete('ih_session', { path: '/' });
          return redirect(`/auth/login?next=${encodeURIComponent(path)}`);
        }
        (locals as Record<string, unknown>).userId    = session.userId;
        (locals as Record<string, unknown>).sessionToken = token;
      }
    } catch (_) {
      return redirect('/auth/login');
    }
  }

  // Redirect logged-in users away from auth pages
  if (isAuthPage && token) {
    return redirect('/dashboard');
  }

  return next();
});
