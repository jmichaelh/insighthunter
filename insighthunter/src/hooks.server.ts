import type { Handle } from '@sveltejs/kit';
import { getSession } from '$lib/server/auth';

// Routes that don't require auth
const PUBLIC_PATHS = ['/', '/login', '/signup', '/forgot-password', '/privacy', '/terms', '/api'];

export const handle: Handle = async ({ event, resolve }) => {
  // Attach session to all requests so any +page.server.ts can access it
  event.locals.session = await getSession(event);

  const path = event.url.pathname;
  const isPublic = PUBLIC_PATHS.some((p) => path === p || path.startsWith(p));

  // Hard redirect for protected routes if session is missing
  if (!isPublic && !event.locals.session) {
    const redirectTo = encodeURIComponent(path);
    return new Response(null, {
      status: 302,
      headers: { Location: `/login?redirectTo=${redirectTo}` },
    });
  }

  return resolve(event);
};
