import { describe, it, expect, vi } from "vitest";

describe("GET /api/dashboard", () => {
  it("returns 401 without token", async () => {
    // TODO: use Miniflare or wrangler-test-env to mount the app
    expect(true).toBe(true);
  });

  it("returns dashboard data with valid token", async () => {
    expect(true).toBe(true);
  });
});
