import type { Actions } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { hashPassword, createSession, sessionCookieOptions } from '$lib/server/auth';

export const actions = {
  default: async ({ request, platform, cookies }) => {
    const db = platform?.env?.INSIGHTHUNTER_DB;
    if (!db) return fail(500, { error: 'Service unavailable. Please try again.' });

    const data = await request.formData();
    const email = String(data.get('email') || '').trim().toLowerCase();
    const password = String(data.get('password') || '');
    const fullName = String(data.get('fullName') || '').trim();
    const companyName = String(data.get('companyName') || '').trim();

    if (!email || !password || !fullName) return fail(400, { error: 'All required fields must be filled.' });
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return fail(400, { error: 'Invalid email address.' });
    if (password.length < 8) return fail(400, { error: 'Password must be at least 8 characters.' });

    const existing = await db.prepare('SELECT id FROM users WHERE email = ?').bind(email).first();
    if (existing) return fail(400, { error: 'An account with this email already exists.' });

    const id = crypto.randomUUID();
    const passwordHash = await hashPassword(password);
    const now = Date.now();

    await db.prepare(
      'INSERT INTO users (id, email, password_hash, full_name, company_name, plan, subscription_status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(id, email, passwordHash, fullName, companyName, 'free', 'active', now, now).run();

    const sessionId = await createSession(db, id);
    const isProduction = platform?.env?.APP_URL?.startsWith('https://insighthunter.com') ?? false;
    cookies.set('ih_session', sessionId, sessionCookieOptions(isProduction));

    redirect(303, '/dashboard');
  }
} satisfies Actions;
