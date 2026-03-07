# insighthunter-main

Insight Hunter Main API — Cloudflare Worker  
Routes: dashboard · reports · forecasts · insights · transactions · clients · settings

## Stack
- **Runtime**: Cloudflare Workers (Hono router)
- **DB**: D1 (SQLite)
- **Cache**: KV
- **Storage**: R2 (PDF reports)
- **Queues**: Report generation + notifications
- **Analytics**: Analytics Engine
- **Auth**: JWT validated via `insighthunter-auth`

## Quick Start

```bash
cp .env.example .dev.vars

# Create D1 database
wrangler d1 create insighthunter-main-db

# Create KV namespaces
wrangler kv:namespace create CACHE
wrangler kv:namespace create RATE_LIMIT

# Create R2 bucket
wrangler r2 bucket create insighthunter-reports

# Create Queues
wrangler queues create insighthunter-report-queue
wrangler queues create insighthunter-notification-queue

# Run migrations
npm run migrate:local

# Set secrets
wrangler secret put JWT_SECRET
wrangler secret put SERVICE_API_KEY

# Dev
npm run dev

# Deploy
npm run deploy
