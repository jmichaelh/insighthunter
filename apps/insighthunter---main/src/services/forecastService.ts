import type { Env, ForecastResult, ForecastPeriod } from "@/types";
import { getTrendData } from "@/db/queries";
import { cacheGetOrSet } from "@/lib/cache";

/**
 * Linear regression forecast over historical monthly data.
 * For production, delegate to insighthunter-agents ForecastAgent.
 */
export async function getForecast(
  env: Env,
  orgId: string,
  horizonMonths = 6
): Promise<ForecastResult> {
  const cacheKey = `forecast:${orgId}:${horizonMonths}`;

  return cacheGetOrSet(env.CACHE, cacheKey, async () => {
    const history = await getTrendData(env.DB, orgId, 12);
    if (history.length < 2) {
      return { periods: [], confidence: 0, generatedAt: new Date().toISOString(), modelVersion: "linear-v1" };
    }

    // Simple linear regression on revenue
    const n  = history.length;
    const xs = history.map((_, i) => i);
    const ys = history.map(h => h.revenue);
    const xMean = xs.reduce((a, b) => a + b, 0) / n;
    const yMean = ys.reduce((a, b) => a + b, 0) / n;
    const slope = xs.reduce((s, x, i) => s + (x - xMean) * (ys[i] - yMean), 0) /
                  xs.reduce((s, x) => s + (x - xMean) ** 2, 0);
    const intercept = yMean - slope * xMean;

    // Project forward
    const lastDate  = new Date(history[history.length - 1].period + "-01");
    const expSlope  = history.map(h => h.expenses).reduce((a, b) => a + b, 0) / n;
    const periods: ForecastPeriod[] = [];

    for (let i = 1; i <= horizonMonths; i++) {
      const d = new Date(lastDate);
      d.setMonth(d.getMonth() + i);
      const period = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
      const projRev = Math.max(0, intercept + slope * (n + i - 1));
      const projExp = expSlope;
      const band    = projRev * 0.15;
      periods.push({
        period,
        projectedRev: Math.round(projRev),
        projectedExp: Math.round(projExp),
        projectedNet: Math.round(projRev - projExp),
        lower:        Math.round(projRev - band),
        upper:        Math.round(projRev + band),
      });
    }

    return {
      periods,
      confidence:   Math.min(0.85, 0.5 + n * 0.03),
      generatedAt:  new Date().toISOString(),
      modelVersion: "linear-v1",
    };
  }, 600); // cache 10 min
}
