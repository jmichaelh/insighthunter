// packages/auth-middleware/src/index.ts
import * as jose from 'jose';

export interface AuthEnv {
  JWT_SECRET: string;
  LOGIN_SESSION_CACHE?: KVNamespace; // optional — auth app has it, others don't need it
  ENVIRONMENT?: string;
}

export interface AuthLocals {
  userId: string | null;
  userEmail: string | null;
  subscriptionTier: string | null;
}

export async function resolveAuth(
  cookieHeader: string | null,
  jwtSecret: string
): Promise<AuthLocals> {
  const defaults: AuthLocals = { userId: null, userEmail: null, subscriptionTier: null };

  if (!cookieHeader) return defaults;

  // Parse auth_token from cookie string
  const token = cookieHeader
    .split(';')
    .map(c => c.trim())
    .find(c => c.startsWith('auth_token='))
    ?.slice('auth_token='.length);

  if (!token) return defaults;

  try {
    const { payload } = await jose.jwtVerify(
      token,
      new TextEncoder().encode(jwtSecret)
    );
    return {
      userId:           (payload.sub as string)   ?? null,
      userEmail:        (payload.email as string)  ?? null,
      subscriptionTier: (payload.tier as string)   ?? 'free',
    };
  } catch {
    return defaults;
  }
}

// Protected route prefixes — same across all apps
export const PROTECTED_PREFIXES = [
  '/dashboard',
  '/upload',
  '/account',
  '/api/upload',
  '/api/reports',
  '/api/account',
];

export async function signAuthJWT(
    userID:  string,
    email:   string,
    tier:    string,
    secret:  string
    ): Promise<string> {
     return new jose.SignJWT({ sub: userID, email, tier })
        .setProtectedHeader({ alg: 'HS256' })
        .setIssuedAt()
        .setExpirationTime('7d')
        .sign(new TextEncoder().encode(secret));
}

export function isProtectedRoute(pathname: string): boolean {
  return PROTECTED_PREFIXES.some(p => pathname.startsWith(p));
}

export function isAuthRoute(pathname: string): boolean {
  return pathname.startsWith('/auth/');
}
