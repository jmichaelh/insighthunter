// packages/auth-middleware/src/index.ts
import type { AuthContext, VerifyResponse } from '/home/user/insighthunter/apps/insighthunter-auth/src/types/auth.ts';

export type { AuthContext };

export async function authMiddleware(
  request: Request,
  authWorker: Fetcher,         // AUTH_WORKER service binding
  options: { required?: boolean } = { required: true }
): Promise<AuthContext | null> {
  const token = request.headers.get('Authorization')?.replace('Bearer ', '');
  if (!token) {
    if (options.required) throw new AuthError('NO_TOKEN', 401);
    return null;
  }

  const res  = await authWorker.fetch('https://auth/internal/verify', {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({ token }),
  });

  const data = await res.json<VerifyResponse>();
  if (!data.valid || !data.context) {
    if (options.required) throw new AuthError(data.error ?? 'INVALID_TOKEN', 401);
    return null;
  }

  return data.context;
}

export class AuthError extends Error {
  constructor(public code: string, public status: number) {
    super(code);
  }
}
