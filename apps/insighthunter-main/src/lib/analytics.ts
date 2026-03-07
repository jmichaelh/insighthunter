import type { Env } from "@/types";

export type EventName =
  | "dashboard_viewed"
  | "report_generated"
  | "report_exported"
  | "forecast_run"
  | "insight_generated"
  | "transaction_imported"
  | "client_created"
  | "api_error";

export function trackEvent(
  env: Env,
  event: EventName,
  orgId: string,
  meta: Record<string, string | number | boolean> = {}
): void {
  try {
    env.EVENTS.writeDataPoint({
      blobs:   [event, orgId, env.APP_ENV],
      doubles: [Date.now()],
      indexes: [orgId],
    });
  } catch {
    // non-blocking — never throw from analytics
  }
}
