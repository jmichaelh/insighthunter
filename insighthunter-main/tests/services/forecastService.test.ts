import { describe, it, expect, vi } from "vitest";
import { getForecast } from "../../src/services/forecastService";

describe("forecastService", () => {
  it("returns empty forecast for insufficient history", async () => {
    const mockEnv = {
      DB:    { prepare: vi.fn().mockReturnValue({ bind: vi.fn().mockReturnValue({ all: vi.fn().mockResolvedValue({ results: [] }) }) }) },
      CACHE: { get: vi.fn().mockResolvedValue(null), put: vi.fn().mockResolvedValue(undefined) },
    } as any;

    const result = await getForecast(mockEnv, "org-123", 6);
    expect(result.periods).toHaveLength(0);
    expect(result.confidence).toBe(0);
  });

  it("projects forward months correctly", async () => {
    const history = Array.from({ length: 6 }, (_, i) => ({
      period:   `2025-${String(i + 1).padStart(2, "0")}`,
      revenue:  5000 + i * 200,
      expenses: 3000,
    }));
    const mockEnv = {
      DB:    { prepare: vi.fn().mockReturnValue({ bind: vi.fn().mockReturnValue({ all: vi.fn().mockResolvedValue({ results: history }) }) }) },
      CACHE: { get: vi.fn().mockResolvedValue(null), put: vi.fn().mockResolvedValue(undefined) },
    } as any;

    const result = await getForecast(mockEnv, "org-123", 3);
    expect(result.periods).toHaveLength(3);
    expect(result.periods[0].projectedRev).toBeGreaterThan(0);
  });
});
