import type { RequestEvent } from '@sveltejs/kit';

export const SESSION_COOKIE = 'ih_session';
export const SESSION_TTL = 60 * 60 * 24 * 7; // 7 days in seconds

export interface SessionData {
  userId: string;
  email: string;
  name: string;
  plan: 'lite' | 'standard' | 'enterprise';
  qbConnected: boolean;
  createdAt: number;
}

/** Read and validate a session from KV */
export async function getSession(
  event: RequestEvent
): Promise<SessionData | null> {
  const token = event.cookies.get(SESSION_COOKIE);
  if (!token) return null;

  const kv: KVNamespace = event.platform?.env?.IH_SESSIONS;
  if (!kv) return null;

  try {
    const raw = await kv.get(`session:${token}`);
    if (!raw) return null;
    return JSON.parse(raw) as SessionData;
  } catch {
    return null;
  }
}

/** Create a new session in KV and set the cookie */
export async function createSession(
  event: RequestEvent,
   SessionData
): Promise<string> {
  const kv: KVNamespace = event.platform?.env?.IH_SESSIONS;
  const token = crypto.randomUUID();

  await kv.put(`session:${token}`, JSON.stringify(data), {
    expirationTtl: SESSION_TTL,
  });

  event.cookies.set(SESSION_COOKIE, token, {
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
    path: '/',
    maxAge: SESSION_TTL,
  });

  return token;
}

/** Destroy a session from KV and clear the cookie */
export async function destroySession(event: RequestEvent): Promise<void> {
  const token = event.cookies.get(SESSION_COOKIE);
  if (!token) return;

  const kv: KVNamespace = event.platform?.env?.IH_SESSIONS;
  await kv?.delete(`session:${token}`);

  event.cookies.delete(SESSION_COOKIE, { path: '/' });
}

/** Redirect unauthenticated users — call in every protected +page.server.ts */
export function requireAuth(session: SessionData | null, url: URL) {
  if (!session) {
    const redirectTo = encodeURIComponent(url.pathname);
    return { redirect: `/login?redirectTo=${redirectTo}` };
  }
  return null;
}
