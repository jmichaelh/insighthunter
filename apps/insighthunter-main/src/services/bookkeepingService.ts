import type { Env } from "@/types";
import { logger } from "@/lib/logger";

/** Proxies requests to insighthunter-bookkeeping service */
export async function syncBookkeepingData(
  env: Env,
  orgId: string
): Promise<{ synced: boolean; recordCount: number }> {
  try {
    const res = await fetch(`${env.BOOKKEEPING_SERVICE_URL}/api/sync`, {
      method:  "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Api-Key":    env.SERVICE_API_KEY,
        "X-Org-Id":     orgId,
      },
      body: JSON.stringify({ orgId }),
    });
    if (!res.ok) throw new Error(`Bookkeeping service ${res.status}`);
    return res.json() as Promise<{ synced: boolean; recordCount: number }>;
  } catch (e) {
    logger.warn("Bookkeeping service unavailable", { error: String(e) });
    return { synced: false, recordCount: 0 };
  }
}
