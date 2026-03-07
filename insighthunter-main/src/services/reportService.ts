import type { Env, ReportRecord, ProfitLoss } from "@/types";
import { getKPIAggregates, getReports } from "@/db/queries";
import { storeReport } from "@/lib/pdf";

export async function buildPLReport(
  env: Env,
  orgId: string,
  userId: string,
  start: string,
  end: string
): Promise<ReportRecord> {
  const agg = await getKPIAggregates(env.DB, orgId, start, end);
  const pl: ProfitLoss = {
    periodStart:   start,
    periodEnd:     end,
    totalRevenue:  agg.revenue,
    totalExpenses: agg.expenses,
    netIncome:     agg.revenue - agg.expenses,
    grossMargin:   agg.revenue > 0 ? ((agg.revenue - agg.expenses) / agg.revenue) * 100 : 0,
    rows:          [],
  };

  return storeReport(env, orgId, userId, "pl", `P&L ${start} – ${end}`, start, end, pl);
}

export async function listReports(
  env: Env,
  orgId: string
): Promise<ReportRecord[]> {
  return getReports(env.DB, orgId, 20);
}

export async function getReportFile(
  env: Env,
  r2Key: string
): Promise<R2ObjectBody | null> {
  return env.REPORTS_BUCKET.get(r2Key);
}
