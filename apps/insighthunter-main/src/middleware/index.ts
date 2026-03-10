import { defineMiddleware } from 'astro:middleware';

const PUBLIC_ROUTES = [
  '/',
  '/pricing',
  '/about',
  '/contact',
  '/features',
  '/auth/login',
  '/auth/register',
  '/auth/forgot-password',
  '/auth/callback',
  '/api',
];

function isPublic(pathname: string): boolean {
  return PUBLIC_ROUTES.some(r => pathname === r || pathname.startsWith(r + '/'))
    || pathname.startsWith('/features/')
    || pathname.startsWith('/_astro/')
    || pathname.startsWith('/icons/')
    || pathname.match(/\.(ico|svg|png|webmanifest|css|js)$/) !== null;
}

export const onRequest = defineMiddleware(async (context, next) => {
  const { pathname } = new URL(context.request.url);

  if (isPublic(pathname)) return next();

  // Validate session cookie
  const token = context.cookies.get('ih_session')?.value;
  if (!token) {
    return context.redirect(`/auth/login?redirect=${encodeURIComponent(pathname)}`);
  }

  try {
    const res = await (context.locals as any).runtime.env.AUTH_WORKER.fetch(
      new Request('https://auth/verify', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ token }),
      })
    );

    if (!res.ok) throw new Error('Invalid session');

    const auth = await res.json({ 
      userId: string;
      orgId:  string;
      email:  string;
      role:   string;
    })();

    context.locals.auth = auth;
    return next();
  } catch {
    context.cookies.delete('ih_session', { path: '/' });
    return context.redirect(`/auth/login?redirect=${encodeURIComponent(pathname)}`);
  }
});
