import type { TokenPayload } from "../../src/types";

export const mockUser: TokenPayload = {
  sub:   "user-test-001",
  email: "test@insighthunter.com",
  name:  "Test User",
  tier:  "standard",
  orgId: "org-test-001",
  iat:   Math.floor(Date.now() / 1000),
  exp:   Math.floor(Date.now() / 1000) + 3600,
};
