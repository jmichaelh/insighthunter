import type { Env, AccessTokenPayload, RefreshTokenPayload } from "@/types";
import {
  createAccessToken,
  createRefreshToken,
  verifyRefreshToken,
} from "@/lib/jwt";
import {
  storeRefreshJTI,
  revokeJTI,
  isJTIValid,
} from "@/lib/cache";
import { logger } from "@/lib/logger";

export interface IssuedTokens {
  accessToken:  string;
  refreshToken: string;
  expiresIn:    number;
  tokenType:    "Bearer";
}

export async function issueTokens(
  env: Env,
  user: { id: string; email: string; name: string; org_id: string; role: string; tier: string }
): Promise<IssuedTokens> {
  const jwtExpiry     = parseInt(env.JWT_EXPIRY     ?? "3600");
  const refreshExpiry = parseInt(env.REFRESH_EXPIRY ?? "2592000");

  const [accessToken, { token: refreshToken, jti }] = await Promise.all([
    createAccessToken(user, env.JWT_SECRET, jwtExpiry),
    createRefreshToken(user.id, env.REFRESH_SECRET, refreshExpiry),
  ]);

  await storeRefreshJTI(env.TOKENS, jti, user.id, refreshExpiry);
  logger.debug("Tokens issued", { userId: user.id, jti });

  return { accessToken, refreshToken, expiresIn: jwtExpiry, tokenType: "Bearer" };
}

export async function rotateRefreshToken(
  env: Env,
  oldRefreshToken: string,
  getUser: (id: string) => Promise<{ id: string; email: string; name: string; org_id: string; role: string; tier: string } | null>
): Promise<IssuedTokens | null> {
  const payload = await verifyRefreshToken(oldRefreshToken, env.REFRESH_SECRET);
  if (!payload) { logger.warn("Refresh token invalid or expired"); return null; }

  const valid = await isJTIValid(env.TOKENS, payload.jti);
  if (!valid) { logger.warn("Refresh JTI already revoked", { jti: payload.jti }); return null; }

  // Revoke old JTI before issuing new tokens (token rotation)
  await revokeJTI(env.TOKENS, payload.jti);

  const user = await getUser(payload.sub);
  if (!user) return null;

  return issueTokens(env, user);
}

export async function revokeRefreshToken(
  env: Env,
  refreshToken: string
): Promise<void> {
  const payload = await verifyRefreshToken(refreshToken, env.REFRESH_SECRET);
  if (payload) await revokeJTI(env.TOKENS, payload.jti);
}

export async function verifyAccessTokenForService(
  env: Env,
  token: string
): Promise<AccessTokenPayload | null> {
  const { verifyAccessToken } = await import("@/lib/jwt");
  return verifyAccessToken(token, env.JWT_SECRET);
}
