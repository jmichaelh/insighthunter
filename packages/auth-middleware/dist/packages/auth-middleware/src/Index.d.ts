import type { AuthContext } from '/home/user/insighthunter/apps/insighthunter-auth/src/types/auth.ts';
export type { AuthContext };
export declare function authMiddleware(request: Request, authWorker: Fetcher, // AUTH_WORKER service binding
options?: {
    required?: boolean;
}): Promise<AuthContext | null>;
export declare class AuthError extends Error {
    code: string;
    status: number;
    constructor(code: string, status: number);
}
