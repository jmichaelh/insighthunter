import type { ApiResult } from '@/types/api';

const BASE = import.meta.env.PUBLIC_APP_URL ?? '';

async function request<T>(
  path:    string,
  options: RequestInit = {},
): Promise<ApiResult<T>> {
  const res = await fetch(`${BASE}/api${path}`, {
    ...options,
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
  });

  if (res.status === 401) {
    window.location.href = `/auth/login?redirect=${encodeURIComponent(window.location.pathname)}`;
    return { error: 'Unauthorized', status: 401 };
  }

  const json = await res.json<any>();
  if (!res.ok) return { error: json.error ?? 'Unknown error', status: res.status };
  return { data: json.data };
}

export const api = {
  get:    <T>(path: string)                       => request<T>(path),
  post:   <T>(path: string, body: unknown)        => request<T>(path, { method: 'POST',  body: JSON.stringify(body) }),
  patch:  <T>(path: string, body: unknown)        => request<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
  delete: <T>(path: string)                       => request<T>(path, { method: 'DELETE' }),
};
