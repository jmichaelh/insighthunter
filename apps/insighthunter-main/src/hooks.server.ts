import type { Handle } from '@sveltejs/kit';
import { getUserBySession } from '$lib/server/auth';

export const handle: Handle = async ({ event, resolve }) => {
  const sessionId = event.cookies.get('ih_session');
  if (sessionId && event.platform?.env?.INSIGHTHUNTER_DB) {
    try {
      const row = await getUserBySession(event.platform.env.INSIGHTHUNTER_DB, sessionId);
      if (row) {
        event.locals.user = {
          id: row.id as string,
          email: row.email as string,
          fullName: row.full_name as string,
          companyName: row.company_name as string,
          plan: row.plan as string,
          subscriptionStatus: row.subscription_status as string
        };
        event.locals.sessionId = sessionId;
      }
    } catch (err) {
      console.error('Session lookup error:', err);
    }
  }
  return resolve(event);
};
