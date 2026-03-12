import type { Env, DashboardData, KPISnapshot } from "@/types";
import { getKPIAggregates, getTrendData } from "@/db/queries";
import { cacheGetOrSet } from "@/lib/cache";

export async function getDashboardData(
  env: Env,
  orgId: string
): Promise<DashboardData> {
  const cacheKey = `dashboard:${orgId}`;

  return cacheGetOrSet(env.CACHE, cacheKey, async () => {
    const now   = new Date();
    const start = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;
    const end   = now.toISOString().split("T")[0];

    const [agg, trend] = await Promise.all([
      getKPIAggregates(env.DB, orgId, start, end),
      getTrendData(env.DB, orgId, 6),
    ]);

    const net         = agg.revenue - agg.expenses;
    const grossMargin = agg.revenue > 0 ? ((net / agg.revenue) * 100) : 0;

    const kpis: KPISnapshot = {
      revenue:     agg.revenue,
      expenses:    agg.expenses,
      netIncome:   net,
      cashBalance: agg.revenue,   // replace with real bank balance
      grossMargin: Math.round(grossMargin * 100) / 100,
      period:      `${start} – ${end}`,
      asOf:        new Date().toISOString(),
    };

    return {
      kpis,
      recentAlerts: [],
      trendData: trend.map(t => ({
        period:   t.period,
        revenue:  t.revenue,
        expenses: t.expenses,
        net:      t.revenue - t.expenses,
      })),
    } satisfies DashboardData;
  }, 120); // cache 2 min
}
