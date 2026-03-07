import type { AccessTokenPayload, RefreshTokenPayload } from "@/types";

// ── Helpers ───────────────────────────────────────────────────────────────────
function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let b64 = btoa(String.fromCharCode(...bytes));
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function decodeBase64url(str: string): string {
  const b64 = str.replace(/-/g, "+").replace(/_/g, "/");
  return atob(b64);
}

async function importKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"]
  );
}

// ── Sign ──────────────────────────────────────────────────────────────────────
export async function signJWT(
  payload: Record<string, unknown>,
  secret: string
): Promise<string> {
  const header  = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body    = base64url(JSON.stringify(payload));
  const key     = await importKey(secret);
  const sigBuf  = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${header}.${body}`));
  const sig     = base64url(sigBuf);
  return `${header}.${body}.${sig}`;
}

// ── Verify ────────────────────────────────────────────────────────────────────
export async function verifyJWT<T extends { exp?: number; type?: string }>(
  token: string,
  secret: string,
  expectedType?: string
): Promise<T | null> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const [header, body, sig] = parts;

    const key    = await importKey(secret);
    const sigBuf = Uint8Array.from(decodeBase64url(sig), c => c.charCodeAt(0));
    const valid  = await crypto.subtle.verify(
      "HMAC", key, sigBuf,
      new TextEncoder().encode(`${header}.${body}`)
    );
    if (!valid) return null;

    const payload = JSON.parse(decodeBase64url(body)) as T;
    if (payload.exp && Date.now() / 1000 > payload.exp) return null;
    if (expectedType && payload.type !== expectedType) return null;
    return payload;
  } catch {
    return null;
  }
}

// ── Token factories ───────────────────────────────────────────────────────────
export async function createAccessToken(
  user: { id: string; email: string; name: string; org_id: string; role: string; tier: string },
  secret: string,
  expirySeconds: number
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload: AccessTokenPayload = {
    sub:   user.id,
    email: user.email,
    name:  user.name,
    orgId: user.org_id,
    role:  user.role as AccessTokenPayload["role"],
    tier:  user.tier as AccessTokenPayload["tier"],
    type:  "access",
    iat:   now,
    exp:   now + expirySeconds,
  };
  return signJWT(payload, secret);
}

export async function createRefreshToken(
  userId: string,
  secret: string,
  expirySeconds: number
): Promise<{ token: string; jti: string }> {
  const now = Math.floor(Date.now() / 1000);
  const jti = crypto.randomUUID();
  const payload: RefreshTokenPayload = {
    sub:  userId,
    jti,
    type: "refresh",
    iat:  now,
    exp:  now + expirySeconds,
  };
  return { token: await signJWT(payload, secret), jti };
}

export async function verifyAccessToken(token: string, secret: string): Promise<AccessTokenPayload | null> {
  return verifyJWT<AccessTokenPayload>(token, secret, "access");
}

export async function verifyRefreshToken(token: string, secret: string): Promise<RefreshTokenPayload | null> {
  return verifyJWT<RefreshTokenPayload>(token, secret, "refresh");
}
