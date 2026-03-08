
import { defineMiddleware } from 'astro:middleware';

// Added functions to replace the missing @insighthunter/auth-middleware package

const protectedRoutes = ['/dashboard', '/account', '/admin'];
function isProtectedRoute(pathname: string) {
  return protectedRoutes.some(route => pathname.startsWith(route));
}

interface AuthPayload {
    userId: string | null;
    userEmail: string | null;
    subscriptionTier: string | null;
}

interface TokenPayload {
    sub: string;
    email: string;
    tier: string;
    exp?: number;
}

async function resolveAuth(cookie: string | null, secret: string): Promise<AuthPayload> {
    const nullAuth = { userId: null, userEmail: null, subscriptionTier: null };
    if (!cookie) return nullAuth;

    const tokenCookie = cookie.split(';').find(c => c.trim().startsWith('auth_token='));
    if (!tokenCookie) return nullAuth;

    const token = tokenCookie.split('=')[1];
    if (!token) return nullAuth;

    try {
        const [headerB64, payloadB64, sigB64] = token.split(".");
        if (!headerB64 || !payloadB64 || !sigB64) return nullAuth;

        const enc = new TextEncoder();
        const keyData = enc.encode(secret);
        const cryptoKey = await crypto.subtle.importKey("raw", keyData, { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
        const sigBuf = Uint8Array.from(atob(sigB64.replace(/-/g, "+").replace(/_/g, "/")), c => c.charCodeAt(0));
        const data = enc.encode(`${headerB64}.${payloadB64}`);
        const valid = await crypto.subtle.verify("HMAC", cryptoKey, sigBuf, data);

        if (!valid) return nullAuth;

        const payload = JSON.parse(atob(payloadB64)) as TokenPayload;
        if (payload.exp && Date.now() / 1000 > payload.exp) {
            return nullAuth;
        }

        return { userId: payload.sub, userEmail: payload.email, subscriptionTier: payload.tier };
    } catch (err) {
        console.error("Error resolving auth:", err);
        return nullAuth;
    }
}

// Original middleware logic
export const onRequest = defineMiddleware(async ({ locals, request, url, redirect }, next) => {
  const env = locals.runtime?.env;

  const auth = await resolveAuth(
    request.headers.get('cookie'),
    env?.JWT_SECRET ?? ''
  );

  locals.userId           = auth.userId;
  locals.userEmail        = auth.userEmail;
  locals.subscriptionTier = auth.subscriptionTier;

  if (isProtectedRoute(url.pathname)) {
    if (!auth.userId) {
      return redirect(
        `https://insighthunter.app/auth/login?redirect=${encodeURIComponent(url.href)}`
      );
    }
  }

  return next();
});
