import type { RequestEvent } from '@sveltejs/kit';

export interface QBTokens {
  access_token: string;
  refresh_token: string;
  realm_id: string;
  expires_at: number;
}

export interface DashboardKPIs {
  cashOnHand: number;
  monthlyRevenue: number;
  outstandingInvoices: number;
  outstandingCount: number;
  cashFlowHistory: { month: string; inflow: number; outflow: number }[];
}

/** Load stored QB tokens from KV */
async function getQBTokens(
  event: RequestEvent,
  userId: string
): Promise<QBTokens | null> {
  const kv: KVNamespace = event.platform?.env?.IH_SESSIONS;
  const raw = await kv?.get(`qb_tokens:${userId}`);
  return raw ? (JSON.parse(raw) as QBTokens) : null;
}

/** Refresh access token if expired */
async function refreshIfNeeded(
  event: RequestEvent,
  userId: string,
  tokens: QBTokens
): Promise<QBTokens> {
  if (Date.now() < tokens.expires_at - 60_000) return tokens;

  const clientId = event.platform?.env?.QB_CLIENT_ID;
  const clientSecret = event.platform?.env?.QB_CLIENT_SECRET;
  const credentials = btoa(`${clientId}:${clientSecret}`);

  const res = await fetch('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: tokens.refresh_token,
    }),
  });

  const data = await res.json<{
    access_token: string;
    refresh_token: string;
    expires_in: number;
  }>();

  const refreshed: QBTokens = {
    ...tokens,
    access_token: data.access_token,
    refresh_token: data.refresh_token,
    expires_at: Date.now() + data.expires_in * 1000,
  };

  // Persist refreshed tokens
  const kv: KVNamespace = event.platform?.env?.IH_SESSIONS;
  await kv.put(`qb_tokens:${userId}`, JSON.stringify(refreshed), {
    expirationTtl: 60 * 60 * 24 * 90,
  });

  return refreshed;
}

/** Fetch live KPIs from QuickBooks Reporting API */
export async function fetchDashboardKPIs(
  event: RequestEvent,
  userId: string
): Promise<DashboardKPIs | null> {
  let tokens = await getQBTokens(event, userId);
  if (!tokens) return null;

  tokens = await refreshIfNeeded(event, userId, tokens);

  const baseUrl = `https://quickbooks.api.intuit.com/v3/company/${tokens.realm_id}`;
  const headers = {
    Authorization: `Bearer ${tokens.access_token}`,
    Accept: 'application/json',
  };

  // Run all QB queries in parallel
  const [balanceRes, plRes, arRes] = await Promise.all([
    fetch(`${baseUrl}/reports/BalanceSheet?minorversion=65`, { headers }),
    fetch(`${baseUrl}/reports/ProfitAndLoss?date_macro=This+Month&minorversion=65`, { headers }),
    fetch(`${baseUrl}/reports/AgedReceivables?minorversion=65`, { headers }),
  ]);

  const [balance, pl, ar] = await Promise.all([
    balanceRes.json<any>(),
    plRes.json<any>(),
    arRes.json<any>(),
  ]);

  // Parse cash on hand from Balance Sheet
  const cashOnHand = extractValue(balance, 'Cash and cash equivalents') ?? 0;

  // Parse monthly revenue from P&L
  const monthlyRevenue = extractValue(pl, 'Total Income') ?? 0;

  // Parse AR from Aged Receivables
  const outstandingInvoices = extractValue(ar, 'Total') ?? 0;
  const outstandingCount = extractRowCount(ar) ?? 0;

  // Fetch 6-month cash flow history
  const cashFlowHistory = await fetchCashFlowHistory(event, tokens, baseUrl, headers);

  return { cashOnHand, monthlyRevenue, outstandingInvoices, outstandingCount, cashFlowHistory };
}

async function fetchCashFlowHistory(
  event: RequestEvent,
  tokens: QBTokens,
  baseUrl: string,
  headers: Record<string, string>
): Promise<DashboardKPIs['cashFlowHistory']> {
  const months: { month: string; inflow: number; outflow: number }[] = [];
  const now = new Date();

  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const start = d.toISOString().slice(0, 10);
    const end = new Date(d.getFullYear(), d.getMonth() + 1, 0).toISOString().slice(0, 10);
    const label = d.toLocaleString('default', { month: 'short' });

    const res = await fetch(
      `${baseUrl}/reports/ProfitAndLoss?start_date=${start}&end_date=${end}&minorversion=65`,
      { headers }
    );
    const data = await res.json<any>();

    months.push({
      month: label,
      inflow: extractValue(data, 'Total Income') ?? 0,
      outflow: extractValue(data, 'Total Expenses') ?? 0,
    });
  }

  return months;
}

// Helpers to navigate QuickBooks report JSON structure
function extractValue(report: any, label: string): number | null {
  try {
    const rows = report?.Rows?.Row ?? [];
    for (const row of rows) {
      if (row?.Summary?.ColData?.[0]?.value?.includes(label)) {
        return parseFloat(row.Summary.ColData[1]?.value ?? '0');
      }
      if (row?.Rows) {
        const nested = extractValue({ Rows: row.Rows }, label);
        if (nested !== null) return nested;
      }
    }
  } catch { }
  return null;
}

function extractRowCount(report: any): number {
  try {
    return (report?.Rows?.Row ?? []).filter(
      (r: any) => r?.type === 'Data'
    ).length;
  } catch {
    return 0;
  }
}
