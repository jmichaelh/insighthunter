
import { sequence } from 'astro:middleware';
import type { APIContext, MiddlewareNext } from 'astro';

const cors = async (context: APIContext, next: MiddlewareNext) => {
  const origin = context.request.headers.get('Origin') ?? '*';
  const allowed = origin === '*' || origin.endsWith('.insighthunter.app');

  if (context.request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': allowed ? origin : '',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Api-Key',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  const response = await next();
  response.headers.set('Access-Control-Allow-Origin', allowed ? origin : '');
  response.headers.set('Vary', 'Origin');
  return response;
};

const rateLimit = async (context: APIContext, next: MiddlewareNext) => {
  // TODO: implement rate limiting with KV
  return next();
};

const auth = async (context: APIContext, next: MiddlewareNext) => {
  const protectedRoutes = ['/dashboard', '/account', '/admin'];
  const { pathname } = context.url;

  const isProtected = protectedRoutes.some((r) => pathname.startsWith(r));
  if (isProtected) {
    const session = context.cookies.get('ih_token');
    if (!session) {
      return context.redirect(`/auth/login?next=${encodeURIComponent(pathname)}`);
    }
  }

  return next();
};

export const onRequest = sequence(cors, rateLimit, auth);
