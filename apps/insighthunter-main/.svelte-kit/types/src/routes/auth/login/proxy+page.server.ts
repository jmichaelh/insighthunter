// @ts-nocheck
import type { Actions, PageServerLoad } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { verifyPassword, createSession, sessionCookieOptions } from '$lib/server/auth';

export const load = async ({ locals }: Parameters<PageServerLoad>[0]) => {
  if (locals.user) redirect(303, '/dashboard');
  return {};
};

export const actions = {
  default: async ({ request, platform, cookies, url }) => {
    const db = platform?.env?.INSIGHTHUNTER_DB;
    if (!db) return fail(500, { error: 'Service unavailable.' });

    const data = await request.formData();
    const email = String(data.get('email') || '').trim().toLowerCase();
    const password = String(data.get('password') || '');

    if (!email || !password) return fail(400, { error: 'Email and password are required.' });

    const user = await db.prepare('SELECT id, password_hash FROM users WHERE email = ?').bind(email).first();
    if (!user) return fail(401, { error: 'Invalid email or password.' });

    const valid = await verifyPassword(password, user.password_hash as string);
    if (!valid) return fail(401, { error: 'Invalid email or password.' });

    const sessionId = await createSession(db, user.id as string);
    const isProduction = platform?.env?.APP_URL?.startsWith('https://insighthunter.com') ?? false;
    cookies.set('ih_session', sessionId, sessionCookieOptions(isProduction));

    const redirectTo = url.searchParams.get('redirect') || '/dashboard';
    redirect(303, redirectTo);
  }
} satisfies Actions;
