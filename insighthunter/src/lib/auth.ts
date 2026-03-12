import type { AuthUser, Session } from '~/types';

const SESSION_KEY = 'ih_session';
const USER_KEY    = 'ih_user';

export function getSessionToken(): string | null {
  if (typeof localStorage === 'undefined') return null;
  return localStorage.getItem(SESSION_KEY);
}

export function setSession(token: string, user: AuthUser): void {
  localStorage.setItem(SESSION_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function clearSession(): void {
  localStorage.removeItem(SESSION_KEY);
  localStorage.removeItem(USER_KEY);
}

export function getStoredUser(): AuthUser | null {
  if (typeof localStorage === 'undefined') return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try { return JSON.parse(raw) as AuthUser; }
  catch { return null; }
}

export async function logout(): Promise<void> {
  const token = getSessionToken();
  if (token) {
    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
    } catch (_) { /* best-effort */ }
  }
  clearSession();
  window.location.href = '/auth/login';
}

export function isLoggedIn(): boolean {
  return !!getSessionToken();
}

export function authHeaders(): Record<string, string> {
  const token = getSessionToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}
