import type { Env, Alert } from "@/types";
import { logger } from "@/lib/logger";

export interface KPIThresholds {
  cashLowThreshold?:       number;
  expenseSpikePercent?:    number;
  revenueDropPercent?:     number;
}

export async function checkThresholds(
  env: Env,
  orgId: string,
  kpis: { revenue: number; expenses: number; cashBalance: number },
  thresholds: KPIThresholds = {}
): Promise<Alert[]> {
  const alerts: Alert[] = [];
  const {
    cashLowThreshold    = 5000,
    expenseSpikePercent = 20,
    revenueDropPercent  = 15,
  } = thresholds;

  if (kpis.cashBalance < cashLowThreshold) {
    alerts.push({
      id:        crypto.randomUUID(),
      type:      "cash_low",
      message:   `Cash balance is below $${cashLowThreshold.toLocaleString()}.`,
      severity:  "warning",
      createdAt: new Date().toISOString(),
    });
  }

  if (alerts.length > 0) {
    try {
      await env.NOTIFICATION_QUEUE.send({ orgId, alerts });
    } catch (e) {
      logger.warn("Notification queue send failed", { error: String(e) });
    }
  }

  return alerts;
}
