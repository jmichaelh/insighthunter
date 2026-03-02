// apps/insighthunter-lite/src/pages/api/reports/index.ts
import type { APIRoute } from 'astro';

export const GET: APIRoute = async ({ locals }) => {
  const userId = locals.userId;
  if (!userId) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });

  const env = locals.runtime.env;

  const { results } = await env.DB.prepare(`
    SELECT r.id, r.report_type, r.ai_summary, r.created_at,
           u.filename, u.row_count, r.data_json
    FROM reports r
    JOIN uploads u ON u.id = r.upload_id
    WHERE r.user_id = ?
    ORDER BY r.created_at DESC
    LIMIT 20
  `).bind(userId).all();

  const reports = results.map((r: Record<string, unknown>) => ({
    ...r,
    data: JSON.parse(r.data_json as string),
    data_json: undefined,
  }));

  return new Response(JSON.stringify({ reports }), {
    headers: { 'Content-Type': 'application/json' },
  });
};
