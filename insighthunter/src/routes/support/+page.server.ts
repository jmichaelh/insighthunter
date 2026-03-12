import type { Actions, PageServerLoad } from './$types';
import { fail } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ locals }) => {
  return { user: locals.user ?? null };
};

export const actions = {
  submit: async ({ request, platform, locals }) => {
    const db = platform?.env?.INSIGHTHUNTER_DB;
    if (!db) return fail(500, { error: 'Service unavailable' });

    const data = await request.formData();
    const name = String(data.get('name') || '').trim();
    const email = String(data.get('email') || '').trim();
    const subject = String(data.get('subject') || '').trim();
    const message = String(data.get('message') || '').trim();
    const priority = String(data.get('priority') || 'normal');

    if (!name || !email || !subject || !message) return fail(400, { error: 'All fields are required' });
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return fail(400, { error: 'Invalid email address' });
    if (message.length < 20) return fail(400, { error: 'Please describe your issue in more detail' });

    await db.prepare(
      'INSERT INTO support_tickets (id, user_id, name, email, subject, message, priority, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(crypto.randomUUID(), locals.user?.id ?? null, name, email, subject, message, priority, 'open', Date.now()).run();

    return { success: true };
  }
} satisfies Actions;
