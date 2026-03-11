import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { getSession, createSession } from '$lib/server/auth';
import { getUserByEmail, verifyPassword } from '$lib/server/db';

export const load: PageServerLoad = async (event) => {
  // Already logged in → go to dashboard
  const session = await getSession(event);
  if (session) throw redirect(302, '/dashboard');
  return {};
};

export const actions: Actions = {
  default: async (event) => {
    const data = await event.request.formData();
    const email = String(data.get('email') ?? '').trim();
    const password = String(data.get('password') ?? '');
    const redirectTo = event.url.searchParams.get('redirectTo') ?? '/dashboard';

    if (!email || !password) {
      return fail(400, { error: 'Email and password are required.' });
    }

    const user = await getUserByEmail(event, email);

    if (!user || !(await verifyPassword(password, user.password_hash))) {
      // Generic message — don't reveal which field is wrong
      return fail(401, { error: 'Invalid email or password.' });
    }

    await createSession(event, {
      userId: user.id,
      email: user.email,
      name: user.name,
      plan: user.plan,
      qbConnected: user.qb_connected === 1,
      createdAt: Date.now(),
    });

    throw redirect(302, redirectTo.startsWith('/') ? redirectTo : '/dashboard');
  },
};
