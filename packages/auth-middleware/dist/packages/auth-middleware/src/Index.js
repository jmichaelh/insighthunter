export async function authMiddleware(request, authWorker, // AUTH_WORKER service binding
options = { required: true }) {
    const token = request.headers.get('Authorization')?.replace('Bearer ', '');
    if (!token) {
        if (options.required)
            throw new AuthError('NO_TOKEN', 401);
        return null;
    }
    const res = await authWorker.fetch('https://auth/internal/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token }),
    });
    const data = await res.json();
    if (!data.valid || !data.context) {
        if (options.required)
            throw new AuthError(data.error ?? 'INVALID_TOKEN', 401);
        return null;
    }
    return data.context;
}
export class AuthError extends Error {
    code;
    status;
    constructor(code, status) {
        super(code);
        this.code = code;
        this.status = status;
    }
}
