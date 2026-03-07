import { Hono } from "hono";
import { z } from "zod";
import type { Env, TokenPayload, Client } from "@/types";
import { getClients, insertClient } from "@/db/queries";
import { trackEvent } from "@/lib/analytics";

const clients = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

const ClientSchema = z.object({
  name:   z.string().min(1).max(100),
  email:  z.string().email(),
  tier:   z.enum(["lite", "standard", "enterprise"]).default("lite"),
  status: z.enum(["active", "suspended", "trial"]).default("trial"),
});

clients.get("/", async (c) => {
  const user = c.get("user");
  const rows = await getClients(c.env.DB, user.orgId);
  return c.json({ ok: true,  rows });
});

clients.post("/", async (c) => {
  const user   = c.get("user");
  const body   = await c.req.json();
  const parsed = ClientSchema.safeParse(body);
  if (!parsed.success) return c.json({ error: "Invalid request", issues: parsed.error.issues }, 400);

  const client: Omit<Client, "createdAt"> = { id: crypto.randomUUID(), orgId: user.orgId, ...parsed.data };
  await insertClient(c.env.DB, client);
  trackEvent(c.env, "client_created", user.orgId, { tier: parsed.data.tier });
  return c.json({ ok: true,  { id: client.id } }, 201);
});

export default clients;
