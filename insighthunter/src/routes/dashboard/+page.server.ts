import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getSession, requireAuth } from '$lib/server/auth';
import { fetchDashboardKPIs } from '$lib/server/quickbooks';

export const load: PageServerLoad = async (event) => {
  const session = await getSession(event);

  // Guard — redirect to login if no valid session
  const authResult = requireAuth(session, event.url);
  if (authResult) throw redirect(302, authResult.redirect);

  // Fetch live KPIs only if QuickBooks is connected
  const kpis = session!.qbConnected
    ? await fetchDashboardKPIs(event, session!.userId)
    : null;

  return {
    user: {
      name: session!.name,
      email: session!.email,
      plan: session!.plan,
      qbConnected: session!.qbConnected,
    },
    kpis,
  };
};
