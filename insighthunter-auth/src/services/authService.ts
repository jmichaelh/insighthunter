import type { Env, User, AuthResponse, PublicUser } from "@/types";
import type { RegisterBody, LoginBody } from "@/types";
import { hashPassword, verifyPassword } from "@/lib/hash";
import { issueTokens } from "./tokenService";
import { createSession } from "./sessionService";
import { trackAuthEvent } from "@/lib/analytics";
import { logger } from "@/lib/logger";
import {
  getUserByEmail,
  getUserById,
  createUser,
  createOrg,
  insertAuditLog,
} from "@/db/queries";
import { storeVerifyToken } from "@/lib/cache";
import { generateSecureToken } from "@/lib/hash";
import { sendVerificationEmail } from "./emailService";

export function toPublicUser(user: User): PublicUser {
  return {
    id:            user.id,
    email:         user.email,
    name:          user.name,
    orgId:         user.org_id,
    role:          user.role,
    tier:          user.tier,
    emailVerified: user.email_verified === 1,
  };
}

export async function registerUser(
  env: Env,
  body: RegisterBody,
  request: Request
): Promise<AuthResponse> {
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";

  // Check duplicate
  const existing = await getUserByEmail(env.DB, body.email);
  if (existing) {
    trackAuthEvent(env, "register_failed", "unknown", { reason: "duplicate_email" });
    throw Object.assign(new Error("An account with this email already exists."), { status: 409 });
  }

  // Create org
  const orgId       = crypto.randomUUID();
  const orgName     = body.orgName ?? `${body.name}'s Org`;
  await createOrg(env.DB, orgId, orgName, "lite");

  // Create user
  const userId      = crypto.randomUUID();
  const passwordHash = await hashPassword(body.password);

  await createUser(env.DB, {
    id:            userId,
    org_id:        orgId,
    email:         body.email,
    name:          body.name,
    password_hash: passwordHash,
    role:          "owner",
    tier:          "lite",
  });

  // Send verification email
  const verifyToken = generateSecureToken(32);
  await storeVerifyToken(env.TOKENS, verifyToken, userId);
  await sendVerificationEmail(env, body.email, body.name, verifyToken).catch(() => {
    logger.warn("Verification email failed to send", { userId });
  });

  const user = await getUserById(env.DB, userId) as User;
  const tokens = await issueTokens(env, user);
  await createSession(env, userId, orgId, user.role, user.tier, request);
  await insertAuditLog(env.DB, orgId, userId, "register", ip);

  trackAuthEvent(env, "register", orgId);
  logger.info("User registered", { userId, orgId });

  return { ok: true, tokens, user: toPublicUser(user) };
}

export async function loginUser(
  env: Env,
  body: LoginBody,
  request: Request
): Promise<AuthResponse> {
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";

  const user = await getUserByEmail(env.DB, body.email);
  if (!user) {
    trackAuthEvent(env, "login_failed", "unknown", { reason: "not_found" });
    throw Object.assign(new Error("Invalid email or password."), { status: 401 });
  }

  if (user.status === "suspended") {
    throw Object.assign(new Error("Your account has been suspended. Contact support."), { status: 403 });
  }

  const valid = await verifyPassword(body.password, user.password_hash);
  if (!valid) {
    await insertAuditLog(env.DB, user.org_id, user.id, "login_failed", ip);
    trackAuthEvent(env, "login_failed", user.org_id, { reason: "bad_password" });
    throw Object.assign(new Error("Invalid email or password."), { status: 401 });
  }

  const tokens = await issueTokens(env, user);
  await createSession(env, user.id, user.org_id, user.role, user.tier, request);
  await insertAuditLog(env.DB, user.org_id, user.id, "login", ip);

  trackAuthEvent(env, "login", user.org_id);
  logger.info("User logged in", { userId: user.id });

  return { ok: true, tokens, user: toPublicUser(user) };
}
