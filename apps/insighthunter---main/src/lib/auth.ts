import type { AuthUser } from '@/types/auth';

export function getStoredUser(): AuthUser | null {
  try {
    const raw = sessionStorage.getItem('ih_user');
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
}

export function storeUser(user: AuthUser): void {
  sessionStorage.setItem('ih_user', JSON.stringify(user));
}

export function clearUser(): void {
  sessionStorage.removeItem('ih_user');
}

export async function logout(): Promise<void> {
  await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' });
  clearUser();
  window.location.href = '/auth/login';
}
