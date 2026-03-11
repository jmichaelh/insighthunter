import type { RequestEvent } from '@sveltejs/kit';
import { sha256 } from './crypto';

export interface UserRow {
  id: string;
  email: string;
  name: string;
  password_hash: string;
  plan: 'lite' | 'standard' | 'enterprise';
  qb_connected: number; // 0 | 1 in SQLite
}

export async function getUserByEmail(
  event: RequestEvent,
  email: string
): Promise<UserRow | null> {
  const db: D1Database = event.platform?.env?.IH_DB;
  if (!db) return null;

  const result = await db
    .prepare('SELECT * FROM users WHERE email = ?1 LIMIT 1')
    .bind(email.toLowerCase().trim())
    .first<UserRow>();

  return result ?? null;
}

export async function verifyPassword(
  plain: string,
  hash: string
): Promise<boolean> {
  const inputHash = await sha256(plain);
  return inputHash === hash;
}
