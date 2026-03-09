export interface AuthUser {
    userId: string;
    orgId:  string;
    email:  string;
    role:   'owner' | 'admin' | 'member' | 'viewer';
  }
  
  export interface Session {
    token:     string;
    expiresAt: number;
    user:      AuthUser;
  }
  
  // Extend Astro locals
  declare module 'astro' {
    interface Locals {
      auth: AuthUser | null;
    }
  }
  