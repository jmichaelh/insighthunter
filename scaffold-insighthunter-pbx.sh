#!/bin/bash
ROOT="apps/insighthunter-pbx"

mkdir -p $ROOT/src/{routes,middleware,services,webhooks,db/migrations,lib,types}
mkdir -p $ROOT/tests/{routes,services,fixtures}

# src
echo "." > $ROOT/src/index.ts

# routes
echo "." > $ROOT/src/routes/calls.ts
echo "." > $ROOT/src/routes/sms.ts
echo "." > $ROOT/src/routes/voicemail.ts
echo "." > $ROOT/src/routes/notifications.ts
echo "." > $ROOT/src/routes/contacts.ts

# middleware
echo "." > $ROOT/src/middleware/auth.ts
echo "." > $ROOT/src/middleware/rateLimit.ts
echo "." > $ROOT/src/middleware/cors.ts
echo "." > $ROOT/src/middleware/twilioValidate.ts

# services
echo "." > $ROOT/src/services/callService.ts
echo "." > $ROOT/src/services/smsService.ts
echo "." > $ROOT/src/services/voicemailService.ts
echo "." > $ROOT/src/services/notificationService.ts
echo "." > $ROOT/src/services/contactService.ts
echo "." > $ROOT/src/services/twilioService.ts

# webhooks
echo "." > $ROOT/src/webhooks/twilioCall.ts
echo "." > $ROOT/src/webhooks/twilioSms.ts
echo "." > $ROOT/src/webhooks/twilioStatus.ts

# db
echo "." > $ROOT/src/db/schema.sql
echo "." > $ROOT/src/db/migrations/0001_init.sql
echo "." > $ROOT/src/db/migrations/0002_calls.sql
echo "." > $ROOT/src/db/migrations/0003_contacts.sql
echo "." > $ROOT/src/db/queries.ts

# lib
echo "." > $ROOT/src/lib/twilioClient.ts
echo "." > $ROOT/src/lib/cache.ts
echo "." > $ROOT/src/lib/analytics.ts
echo "." > $ROOT/src/lib/logger.ts

# types
echo "." > $ROOT/src/types/env.ts
echo "." > $ROOT/src/types/pbx.ts
echo "." > $ROOT/src/types/index.ts

# tests
echo "." > $ROOT/tests/routes/calls.test.ts
echo "." > $ROOT/tests/services/smsService.test.ts
echo "." > $ROOT/tests/fixtures/mockCall.ts
echo "." > $ROOT/tests/fixtures/mockContact.ts

# config
echo "." > $ROOT/wrangler.jsonc
echo "." > $ROOT/package.json
echo "." > $ROOT/tsconfig.json
echo "." > $ROOT/README.md

echo "✅ insighthunter-pbx scaffolded"
