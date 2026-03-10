export interface AuthUser {
    id:        string;
    email:     string;
    name:      string;
    orgId:     string;
    role:      'owner' | 'admin' | 'member' | 'viewer';
    plan:      'free' | 'pro' | 'white_label';
    createdAt: string;
  }
  
  export interface AuthOrg {
    id:        string;
    name:      string;
    plan:      'free' | 'pro' | 'white_label';
    ownerId:   string;
    createdAt: string;
  }
  
  // The canonical context every app receives after verification
  export interface AuthContext {
    userId: string;
    orgId:  string;
    email:  string;
    name:   string;
    role:   'owner' | 'admin' | 'member' | 'viewer';
    plan:   'free' | 'pro' | 'white_label';
  }
  
  export interface JWTPayload {
    sub:   string;   // userId
    org:   string;   // orgId
    email: string;
    role:  string;
    plan:  string;
    iat:   number;
    exp:   number;
  }
  
  export interface LoginRequest {import { Hono } from 'hono';
  import type { Env } from '../types/env';
  import { login, register, logout } from '../services/authService';
  
  export const authRoutes = new Hono<{ Bindings: Env }>();
  
  authRoutes.post('/register', async c => {
    const body = await c.req.json();
    try {
      const { user, tokens } = await register(c.env.DB, c.env.KV, c.env.JWT_SECRET, body);
      return c.json({ data: { user, tokens } }, 201);
    } catch (e: any) {
      if (e.message === 'EMAIL_TAKEN') return c.json({ error: 'Email already registered' }, 409);
      throw e;
    }
  });
  
  authRoutes.post('/login', async c => {
    const body = await c.req.json();
    try {
      const { user, tokens } = await login(c.env.DB, c.env.KV, c.env.JWT_SECRET, body);
      return c.json({ data: { user, tokens } });
    } catch (e: any) {
      if (e.message === 'INVALID_CREDENTIALS') return c.json({ error: 'Invalid email or password' }, 401);
      throw e;
    }
  });
  
  authRoutes.post('/logout', async c => {
    const bearer = c.req.header('Authorization')?.replace('Bearer ', '');
    if (!bearer) return c.json({ error: 'No token' }, 401);
    const ctx = await verifyAccessToken(bearer, c.env.JWT_SECRET);
    if (!ctx)  return c.json({ error: 'Invalid token' }, 401);
    await logout(ctx.userId, c.env.KV);
    return c.json({ ok: true });
  });
  
    email:    string;
    password: string;
  }
  
  export interface RegisterRequest {
    email:    string;
    password: string;
    name:     string;
    orgName:  string;
  }
  
  export interface TokenPair {
    accessToken:  string;   // 15 min
    refreshToken: string;   // 30 days (stored in KV)
    expiresIn:    number;
  }
  
  // What the internal /internal/verify endpoint returns
  export interface VerifyResponse {
    valid:   boolean;
    context: AuthContext | null;
    error:   string | null;
  }
  