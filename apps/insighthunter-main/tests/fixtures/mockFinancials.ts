import type { KPISnapshot, TrendPoint } from "../../src/types";

export const mockKPIs: KPISnapshot = {
  revenue:     42500,
  expenses:    28300,
  netIncome:   14200,
  cashBalance: 38750,
  grossMargin: 33.41,
  period:      "2026-03-01 – 2026-03-07",
  asOf:        "2026-03-07T00:00:00.000Z",
};

export const mockTrend: TrendPoint[] = [
  { period: "2025-10", revenue: 38000, expenses: 24000, net: 14000 },
  { period: "2025-11", revenue: 40500, expenses: 25500, net: 15000 },
  { period: "2025-12", revenue: 45000, expenses: 27000, net: 18000 },
  { period: "2026-01", revenue: 39000, expenses: 26000, net: 13000 },
  { period: "2026-02", revenue: 41000, expenses: 27500, net: 13500 },
  { period: "2026-03", revenue: 42500, expenses: 28300, net: 14200 },
];
