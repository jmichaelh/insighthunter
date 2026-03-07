import { describe, it, expect, vi } from "vitest";
import { issueTokens, rotateRefreshToken } from "../../src/services/tokenService";

const mockEnv = {
  JWT_SECRET:     "test_jwt_secret_that_is_long_enough_64chars_minimum_xxxxxxxxxxxxx",
  REFRESH_SECRET: "test_refresh_secret_that_is_long_enough_64chars_minimum_xxxxxxxxx",
  JWT_EXPIRY:     "3600",
  REFRESH_EXPIRY: "2592000",
  TOKENS: {
    put:    vi.fn().mockResolvedValue(undefined),
    get:    vi.fn().mockResolvedValue(JSON.stringify({ valid: true })),
    delete: vi.fn().mockResolvedValue(undefined),
  },
} as any;

const mockUser = {
  id:     "user-001",
  email:  "test@example.com",
  name:   "Test",
  org_id: "org-001",
  role:   "owner",
  tier:   "lite",
};

describe("tokenService.issueTokens", () => {
  it("returns access and refresh tokens", async () => {
    const result = await issueTokens(mockEnv, mockUser);
    expect(result.accessToken).toBeTruthy();
    expect(result.refreshToken).toBeTruthy();
    expect(result.tokenType).toBe("Bearer");
    expect(result.expiresIn).toBe(3600);
  });

  it("access token has 3 segments (HS256 JWT)", async () => {
    const result = await issueTokens(mockEnv, mockUser);
    expect(result.accessToken.split(".")).toHaveLength(3);
  });
});

describe("tokenService.rotateRefreshToken", () => {
  it("returns null for invalid token", async () => {
    const result = await rotateRefreshToken(mockEnv, "bad.token.here", async () => null);
    expect(result).toBeNull();
  });

  it("issues new tokens on valid rotation", async () => {
    const { refreshToken } = await issueTokens(mockEnv, mockUser);
    const result = await rotateRefreshToken(mockEnv, refreshToken, async () => mockUser);
    expect(result).not.toBeNull();
    expect(result?.accessToken).toBeTruthy();
  });
});
