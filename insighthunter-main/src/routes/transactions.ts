import { Hono } from "hono";
import { z } from "zod";
import type { Env, TokenPayload, Transaction } from "@/types";
import { getTransactions, insertTransaction } from "@/db/queries";
import { trackEvent } from "@/lib/analytics";
import { cacheDel } from "@/lib/cache";

const transactions = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

const TxSchema = z.object({
  date:        z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  description: z.string().min(1).max(255),
  amount:      z.number(),
  category:    z.string().default("Uncategorized"),
  account:     z.string().default("Default"),
  source:      z.enum(["qbo", "csv", "manual"]).default("manual"),
});

transactions.get("/", async (c) => {
  const user   = c.get("user");
  const limit  = parseInt(c.req.query("limit") ?? "50");
  const offset = parseInt(c.req.query("offset") ?? "0");
  const rows   = await getTransactions(c.env.DB, user.orgId, Math.min(limit, 200), offset);
  return c.json({ ok: true,  rows, limit, offset });
});

transactions.post("/", async (c) => {
  const user   = c.get("user");
  const body   = await c.req.json();
  const parsed = TxSchema.safeParse(body);
  if (!parsed.success) return c.json({ error: "Invalid request", issues: parsed.error.issues }, 400);

  const tx: Omit<Transaction, "createdAt"> = { id: crypto.randomUUID(), orgId: user.orgId, ...parsed.data };
  await insertTransaction(c.env.DB, tx);
  await cacheDel(c.env.CACHE, `dashboard:${user.orgId}`);
  trackEvent(c.env, "transaction_imported", user.orgId, { source: parsed.data.source });
  return c.json({ ok: true,  { id: tx.id } }, 201);
});

transactions.post("/bulk", async (c) => {
  const user   = c.get("user");
  const { rows } = await c.req.json() as { rows: unknown[] };
  if (!Array.isArray(rows) || rows.length === 0) return c.json({ error: "rows array required" }, 400);
  if (rows.length > 1000) return c.json({ error: "Max 1000 rows per bulk import" }, 400);

  let imported = 0;
  const errors: string[] = [];

  for (const [i, row] of rows.entries()) {
    const parsed = TxSchema.safeParse(row);
    if (!parsed.success) { errors.push(`Row ${i + 1}: ${parsed.error.issues[0]?.message}`); continue; }
    await insertTransaction(c.env.DB, { id: crypto.randomUUID(), orgId: user.orgId, ...parsed.data });
    imported++;
  }

  await cacheDel(c.env.CACHE, `dashboard:${user.orgId}`);
  trackEvent(c.env, "transaction_imported", user.orgId, { source: "bulk", count: imported });
  return c.json({ ok: true,  { imported, errors } });
});

export default transactions;
