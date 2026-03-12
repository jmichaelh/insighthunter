import type { ApiResponse } from '$lib/types';
import { authHeaders, clearSession } from './auth';

const BASE = '';

async function request<T>(
  path: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...authHeaders(),
    ...(options.headers as Record<string, string> ?? {}),
  };

  try {
    const res = await fetch(`${BASE}${path}`, { ...options, headers });

    if (res.status === 401) {
      clearSession();
      window.location.href = '/auth/login';
      return { ok: false, error: 'Unauthorized' };
    }

    const json = await res.json() as ApiResponse<T>;
    return { ok: res.ok, ...json };
  } catch (err) {
    return { ok: false, error: (err as Error).message };
  }
}

export const api = {
  get:    <T>(path: string)                       => request<T>(path),
  post:   <T>(path: string, body: unknown)        => request<T>(path, { method: 'POST',  body: JSON.stringify(body) }),
  put:    <T>(path: string, body: unknown)        => request<T>(path, { method: 'PUT',   body: JSON.stringify(body) }),
  delete: <T>(path: string)                       => request<T>(path, { method: 'DELETE' }),
  patch:  <T>(path: string, body: unknown)        => request<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
};
