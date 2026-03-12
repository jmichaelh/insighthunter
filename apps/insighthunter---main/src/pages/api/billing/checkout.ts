// apps/insighthunter-main/src/pages/api/billing/checkout.ts
import type { APIRoute } from 'astro';

export const POST: APIRoute = async ({ request, locals }) => {
  const res = await (locals.runtime.env.AUTH_WORKER as Fetcher).fetch(
    new Request('https://auth/billing/checkout', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: request.headers.get('Authorization') ?? '',
      },
      body: await request.text(),
    })
  );
  return new Response(await res.text(), { status: res.status, headers: { 'Content-Type': 'application/json' } });
};
