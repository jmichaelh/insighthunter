// apps/insighthunter-bizforma/src/backend/index.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger as honoLogger } from 'hono/logger';
import { HTTPException } from 'hono/http-exception';

import type { Env, FormationCase, ApiError } from './types';
import { registerFormationRoutes } from './routes/formation';
import { registerEntityDeterminationRoutes } from './routes/entityDetermination';
import { registerEinRoutes } from './routes/ein';
import { registerStateRegistrationRoutes } from './routes/stateRegistration';
import { registerTaxAccountRoutes } from './routes/taxAccounts';
import { registerComplianceRoutes } from './routes/compliance';
import { registerDocumentRoutes } from './routes/documents';
import { authMiddleware } from './middleware/auth';
import { requestLogger } from './middleware/logger';

const app = new Hono<{ Bindings: Env; Variables: { userId?: string } }>();

// Global middleware
app.use('*', cors());
app.use('*', honoLogger());
app.use('*', requestLogger);
app.use('*', authMiddleware);

// Health
app.get('/health', (c) => c.json({ ok: true, service: 'bizforma' }));

// Mount domain routes
registerFormationRoutes(app);
registerEntityDeterminationRoutes(app);
registerEinRoutes(app);
registerStateRegistrationRoutes(app);
registerTaxAccountRoutes(app);
registerComplianceRoutes(app);
registerDocumentRoutes(app);

// 404
app.all('*', (c) => c.json<ApiError>({ error: 'Not found' }, 404));

// Error handler
app.onError((err, c) => {
  console.error('Unhandled error', err);

  if (err instanceof HTTPException) {
    return c.json<ApiError>(
      {
        error: err.message,
        details: err.cause instanceof Error ? err.cause.message : undefined,
      },
      err.status
    );
  }

  return c.json<ApiError>({ error: 'Internal server error' }, 500);
});

export default app;
