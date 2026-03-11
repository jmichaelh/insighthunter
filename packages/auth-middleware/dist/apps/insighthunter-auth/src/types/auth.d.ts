export interface AuthUser {
    id: string;
    email: string;
    name: string;
    orgId: string;
    role: 'owner' | 'admin' | 'member' | 'viewer';
    plan: 'free' | 'pro' | 'white_label';
    createdAt: string;
}
export interface AuthOrg {
    id: string;
    name: string;
    plan: 'free' | 'pro' | 'white_label';
    ownerId: string;
    createdAt: string;
}
export interface AuthContext {
    userId: string;
    orgId: string;
    email: string;
    name: string;
    role: 'owner' | 'admin' | 'member' | 'viewer';
    plan: 'free' | 'pro' | 'white_label';
}
export interface JWTPayload {
    sub: string;
    org: string;
    email: string;
    role: string;
    plan: string;
    iat: number;
    exp: number;
}
export interface LoginRequest {
    email: string;
    password: string;
}
export interface RegisterRequest {
    email: string;
    password: string;
    name: string;
    orgName: string;
}
export interface TokenPair {
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
}
export interface VerifyResponse {
    valid: boolean;
    context: AuthContext | null;
    error: string | null;
}
