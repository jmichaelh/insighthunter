import { Hono } from "hono";
import { z } from "zod";
import type { Env, TokenPayload } from "@/types";
import { buildPLReport, listReports, getReportFile } from "@/services/reportService";
import { trackEvent } from "@/lib/analytics";

const reports = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

const GenerateSchema = z.object({
  type:  z.enum(["pl", "cashflow", "balance_sheet"]),
  start: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  end:   z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

reports.get("/", async (c) => {
  const user    = c.get("user");
  const records = await listReports(c.env, user.orgId);
  return c.json({ ok: true,  records });
});

reports.post("/generate", async (c) => {
  const user = c.get("user");
  const body = await c.req.json();
  const parsed = GenerateSchema.safeParse(body);
  if (!parsed.success) return c.json({ error: "Invalid request", issues: parsed.error.issues }, 400);

  const { type, start, end } = parsed.data;
  const record = await buildPLReport(c.env, user.orgId, user.sub, start, end);
  trackEvent(c.env, "report_generated", user.orgId, { type });
  return c.json({ ok: true,  record }, 201);
});

reports.get("/download/:key", async (c) => {
  const user = c.get("user");
  const key  = decodeURIComponent(c.req.param("key"));
  if (!key.startsWith(`reports/${user.orgId}/`)) return c.json({ error: "Forbidden" }, 403);
  const obj  = await getReportFile(c.env, key);
  if (!obj)  return c.json({ error: "Not found" }, 404);
  trackEvent(c.env, "report_exported", user.orgId);
  return new Response(obj.body, { headers: { "Content-Type": "application/json", "Content-Disposition": `attachment; filename="${key.split("/").pop()}"` } });
});

export default reports;
