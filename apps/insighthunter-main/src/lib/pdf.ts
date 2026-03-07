import type { Env, ReportRecord } from "@/types";
import { insertReport } from "@/db/queries";
import { logger } from "./logger";

/**
 * Stores report JSON in R2 and records metadata in D1.
 * Real PDF rendering would use a headless browser via Browser Rendering binding
 * or a third-party PDF service — scaffold uses JSON as placeholder.
 */
export async function storeReport(
  env: Env,
  orgId: string,
  userId: string,
  type: ReportRecord["type"],
  title: string,
  periodStart: string,
  periodEnd: string,
  payload: unknown
): Promise<ReportRecord> {
  const id    = crypto.randomUUID();
  const r2Key = `reports/${orgId}/${type}/${id}.json`;

  await env.REPORTS_BUCKET.put(r2Key, JSON.stringify(payload), {
    httpMeta { contentType: "application/json" },
    customMeta { orgId, type, title },
  });

  const record: Omit<ReportRecord, "createdAt"> = {
    id,
    orgId,
    type,
    title,
    periodStart,
    periodEnd,
    r2Key,
    createdBy: userId,
  };

  await insertReport(env.DB, record);
  logger.info("Report stored", { id, type, orgId });
  return { ...record, createdAt: new Date().toISOString() };
}

export async function getReportSignedUrl(
  env: Env,
  r2Key: string,
  expiresIn = 3600
): Promise<string> {
  // R2 does not yet support presigned URLs natively in Workers — return a
  // /api/reports/download/:key proxy route instead.
  return `/api/reports/download/${encodeURIComponent(r2Key)}`;
}
