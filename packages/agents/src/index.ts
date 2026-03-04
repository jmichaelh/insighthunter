// packages/agents/src/index.ts
import { Agent } from 'agents';
import { OpenAI } from 'openai';
import { PLAN_LIMITS, PLAN_RANK } from '@insighthunter/types';
import type { Plan } from '@insighthunter/types';

// ─── Env ──────────────────────────────────────────────────────────────────────

export interface AgentEnv {
  AUTH_WORKER: Fetcher;                 // service binding → insighthunter-auth
  OPENAI_API_KEY: string;
  AI_GATEWAY_URL?: string;             // optional Cloudflare AI Gateway for caching + logs
}

// ─── Agent State ──────────────────────────────────────────────────────────────

interface CFOAgentState {
  userId: string;
  plan: Plan;
  clientId?: string;
  clientName?: string;
  conversationTurns: number;
  lastActivity: string;
  financialContext?: FinancialContext;
}

interface FinancialContext {
  totalRevenue?: number;
  totalExpenses?: number;
  netIncome?: number;
  cashBalance?: number;
  outstandingInvoices?: number;
  periodLabel?: string;
  topExpenseCategories?: Array<{ category: string; amount: number }>;
  revenueGrowthPct?: number;
}

interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

// ─── Plan-Gated Feature Flags ─────────────────────────────────────────────────

const AI_FEATURES: Record<Plan, {
  basicQA: boolean;
  forecastAnalysis: boolean;
  kpiAlerts: boolean;
  scenarioModeling: boolean;
  multiClientComparison: boolean;
}> = {
  lite:     { basicQA: false, forecastAnalysis: false, kpiAlerts: false, scenarioModeling: false, multiClientComparison: false },
  standard: { basicQA: true,  forecastAnalysis: true,  kpiAlerts: true,  scenarioModeling: false, multiClientComparison: false },
  pro:      { basicQA: true,  forecastAnalysis: true,  kpiAlerts: true,  scenarioModeling: true,  multiClientComparison: true  },
};

// ─── InsightHunter CFO Agent ──────────────────────────────────────────────────

export class CFOAgent extends Agent<AgentEnv, CFOAgentState> {

  // ── Initialization ──────────────────────────────────────────────────────────

  async onStart() {
    if (!this.state?.userId) {
      this.setState({
        userId: '',
        plan: 'lite',
        conversationTurns: 0,
        lastActivity: new Date().toISOString(),
      });
    }
  }

  // ── HTTP: Initialize agent session with user context ────────────────────────

  async onRequest(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // POST /init — called once per session with auth token + optional client context
    if (url.pathname.endsWith('/init') && request.method === 'POST') {
      return this.handleInit(request);
    }

    // POST /chat — main AI conversation endpoint
    if (url.pathname.endsWith('/chat') && request.method === 'POST') {
      return this.handleChat(request);
    }

    // POST /analyze — structured financial analysis (no conversation history)
    if (url.pathname.endsWith('/analyze') && request.method === 'POST') {
      return this.handleAnalyze(request);
    }

    // GET /state — current agent state (for debugging + UI sync)
    if (url.pathname.endsWith('/state') && request.method === 'GET') {
      return Response.json(this.safeState());
    }

    // DELETE /reset — clear conversation history
    if (url.pathname.endsWith('/reset') && request.method === 'DELETE') {
      await this.clearHistory();
      return Response.json({ success: true });
    }

    return Response.json({ error: 'Not found' }, { status: 404 });
  }

  // ── Init: Validate token, load plan, set context ────────────────────────────

  private async handleInit(request: Request): Promise<Response> {
    const { token, clientId, clientName, financialContext } =
      await request.json<{
        token: string;
        clientId?: string;
        clientName?: string;
        financialContext?: FinancialContext;
      }>();

    if (!token) return Response.json({ error: 'token required' }, { status: 400 });

    // Validate token + get plan from auth worker
    const authRes = await this.env.AUTH_WORKER.fetch(
      new Request('https://auth/auth/me', {
        headers: { Authorization: `Bearer ${token}` },
      })
    );

    if (!authRes.ok) {
      return Response.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const { id: userId, plan } = await authRes.json<{ id: string; plan: Plan }>();
    const features = AI_FEATURES[plan];

    // Lite users cannot access the AI agent
    if (!features.basicQA) {
      return Response.json({
        error: 'AI features require Standard or Pro plan',
        upgrade_url: 'https://insighthunter.app/pricing',
        plan,
      }, { status: 402 });
    }

    this.setState({
      userId,
      plan,
      clientId,
      clientName,
      conversationTurns: 0,
      lastActivity: new Date().toISOString(),
      financialContext: financialContext ?? undefined,
    });

    return Response.json({
      ready: true,
      plan,
      features,
      agentId: this.name,
      clientContext: clientName ? `Loaded context for ${clientName}` : 'No client context loaded',
    });
  }

  // ── Chat: Streaming CFO conversation ────────────────────────────────────────

  private async handleChat(request: Request): Promise<Response> {
    const state = this.state;
    if (!state?.userId) {
      return Response.json({ error: 'Agent not initialized. Call /init first.' }, { status: 400 });
    }

    const { message } = await request.json<{ message: string }>();
    if (!message?.trim()) return Response.json({ error: 'message required' }, { status: 400 });

    // Load history from embedded SQLite
    const history = await this.getHistory();
    const systemPrompt = this.buildSystemPrompt(state);

    const messages: ChatMessage[] = [
      { role: 'system', content: systemPrompt },
      ...history.slice(-20), // last 20 turns for context window efficiency
      { role: 'user', content: message },
    ];

    const openai = this.buildOpenAIClient();

    // Streaming response
    const stream = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      stream: true,
      temperature: 0.3,  // lower temp = more consistent financial advice
      max_tokens: 1000,
    });

    // Collect full response for history storage
    let fullResponse = '';
    const encoder = new TextEncoder();

    const readableStream = new ReadableStream({
      async start(controller) {
        for await (const chunk of stream) {
          const text = chunk.choices[0]?.delta?.content ?? '';
          if (text) {
            fullResponse += text;
            controller.enqueue(encoder.encode(` ${JSON.stringify({ text })}\n\n`));
          }
        }
        controller.enqueue(encoder.encode(' [DONE]\n\n'));
        controller.close();
      },
    });

    // Persist to history after stream completes
    this.saveToHistory(message, fullResponse);
    this.setState({
      ...state,
      conversationTurns: (state.conversationTurns ?? 0) + 1,
      lastActivity: new Date().toISOString(),
    });

    return new Response(readableStream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  }

  // ── Analyze: Structured non-conversational financial analysis ────────────────

  private async handleAnalyze(request: Request): Promise<Response> {
    const state = this.state;
    if (!state?.userId) {
      return Response.json({ error: 'Agent not initialized. Call /init first.' }, { status: 400 });
    }

    const features = AI_FEATURES[state.plan];
    const { type, data } = await request.json<{
      type: 'forecast' | 'kpi_summary' | 'scenario' | 'anomaly_detection';
       Record<string, unknown>;
    }>();

    // Enforce plan gates on analysis types
    if (type === 'scenario' && !features.scenarioModeling) {
      return Response.json({
        error: 'Scenario modeling requires Pro plan',
        upgrade_url: 'https://insighthunter.app/pricing',
      }, { status: 402 });
    }
    if ((type === 'forecast' || type === 'kpi_summary') && !features.forecastAnalysis) {
      return Response.json({
        error: 'Forecast analysis requires Standard or Pro plan',
        upgrade_url: 'https://insighthunter.app/pricing',
      }, { status: 402 });
    }

    const prompt = this.buildAnalysisPrompt(type, data, state);
    const openai = this.buildOpenAIClient();

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: this.buildSystemPrompt(state) },
        { role: 'user', content: prompt },
      ],
      temperature: 0.1,
      response_format: { type: 'json_object' },
    });

    const result = JSON.parse(response.choices[0].message.content ?? '{}');
    return Response.json({ analysis: result, type, plan: state.plan });
  }

  // ── SQLite History via this.sql ──────────────────────────────────────────────

  private async getHistory(): Promise<ChatMessage[]> {
    try {
      // Ensure history table exists
      this
        .sql`CREATE TABLE IF NOT EXISTS conversation_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )`;

      const rows = await Array.fromAsync(
        this.sql<{ role: string; content: string }>`
          SELECT role, content FROM conversation_history
          ORDER BY id DESC LIMIT 40
        `
      );
      return rows.reverse().map((r) => ({ role: r.role as 'user' | 'assistant', content: r.content }));
    } catch {
      return [];
    }
  }

  private saveToHistory(userMessage: string, assistantMessage: string): void {
    // Non-blocking write — don't await
    this.sql`INSERT INTO conversation_history (role, content) VALUES ('user', ${userMessage})`;
    this.sql`INSERT INTO conversation_history (role, content) VALUES ('assistant', ${assistantMessage})`;
    // Trim to last 100 entries to control storage
    this.sql`DELETE FROM conversation_history WHERE id NOT IN (SELECT id FROM conversation_history ORDER BY id DESC LIMIT 100)`;
  }

  private async clearHistory(): Promise<void> {
    this.sql`DELETE FROM conversation_history`;
    this.setState({ ...this.state, conversationTurns: 0 });
  }

  // ── Scheduled: Weekly KPI digest (Standard+ only) ────────────────────────────

  async weeklyKPIDigest( { userId: string; financialContext: FinancialContext }) {
    const state = this.state;
    if (!state?.plan || !AI_FEATURES[state.plan].kpiAlerts) return;

    const openai = this.buildOpenAIClient();
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a CFO assistant generating a concise weekly financial digest.' },
        { role: 'user', content: this.buildAnalysisPrompt('kpi_summary', data.financialContext as Record<string, unknown>, state) },
      ],
      temperature: 0.2,
      max_tokens: 500,
    });

    // Store digest result — consuming app reads via /state or webhook
    this.setState({
      ...state,
      financialContext: data.financialContext,
      lastActivity: new Date().toISOString(),
    });

    return response.choices[0].message.content;
  }

  // ── Prompt Builders ──────────────────────────────────────────────────────────

  private buildSystemPrompt(state: CFOAgentState): string {
    const ctx = state.financialContext;
    const clientLine = state.clientName ? `Current client: ${state.clientName}.` : '';
    const planLine = `User plan: ${state.plan}. Available features: ${JSON.stringify(AI_FEATURES[state.plan])}.`;

    const financialLines = ctx ? `
Current Financial Snapshot:
- Revenue: $${ctx.totalRevenue?.toLocaleString() ?? 'N/A'}
- Expenses: $${ctx.totalExpenses?.toLocaleString() ?? 'N/A'}
- Net Income: $${ctx.netIncome?.toLocaleString() ?? 'N/A'}
- Cash Balance: $${ctx.cashBalance?.toLocaleString() ?? 'N/A'}
- Outstanding Invoices: $${ctx.outstandingInvoices?.toLocaleString() ?? 'N/A'}
- Period: ${ctx.periodLabel ?? 'N/A'}
- Revenue Growth: ${ctx.revenueGrowthPct != null ? `${ctx.revenueGrowthPct.toFixed(1)}%` : 'N/A'}
${ctx.topExpenseCategories ? `- Top Expenses: ${ctx.topExpenseCategories.map((e) => `${e.category} ($${e.amount.toLocaleString()})`).join(', ')}` : ''}
`.trim() : 'No financial data loaded yet. Ask the user to upload CSV data or connect their accounts.';

    return `You are InsightHunter's AI CFO Assistant — a precise, trustworthy financial advisor for small businesses and freelancers.

${clientLine}
${planLine}

${financialLines}

Guidelines:
- Be concise, direct, and actionable. No fluff.
- Cite specific numbers from the financial snapshot when available.
- If data is missing, say so and guide the user to upload it.
- Never fabricate numbers. If uncertain, say "based on available data."
- For Lite users, politely explain which features require an upgrade.
- Format currency as $X,XXX. Use plain language, not jargon.
- Keep responses under 300 words unless detailed analysis is explicitly requested.`;
  }

  private buildAnalysisPrompt(
    type: string,
     Record<string, unknown>,
    state: CFOAgentState
  ): string {
    const prompts: Record<string, string> = {
      forecast: `Analyze this financial data and produce a 3-month cash flow forecast. Return JSON with: { forecast: [{month, projectedRevenue, projectedExpenses, projectedCash}], assumptions: string[], risks: string[], recommendations: string[] }. Data: ${JSON.stringify(data)}`,
      kpi_summary: `Analyze this financial data and produce a KPI summary. Return JSON with: { healthScore: number (0-100), kpis: [{name, value, trend, status}], alerts: string[], topRecommendation: string }. Data: ${JSON.stringify(data)}`,
      scenario: `Model 3 financial scenarios (conservative, base, optimistic) from this data. Return JSON with: { scenarios: [{name, description, projectedRevenue, projectedExpenses, netIncome, probability}], recommendation: string }. Data: ${JSON.stringify(data)}`,
      anomaly_detection: `Identify financial anomalies or unusual patterns in this data. Return JSON with: { anomalies: [{description, severity, affectedAmount, recommendation}], summary: string }. Data: ${JSON.stringify(data)}`,
    };
    return prompts[type] ?? `Analyze this financial  ${JSON.stringify(data)}. Return structured JSON insights.`;
  }

  private buildOpenAIClient(): OpenAI {
    return new OpenAI({
      apiKey: this.env.OPENAI_API_KEY,
      // Route through Cloudflare AI Gateway if configured (adds caching + logs)
      baseURL: this.env.AI_GATEWAY_URL ?? undefined,
    });
  }

  private safeState() {
    const s = this.state;
    return {
      initialized: !!s?.userId,
      plan: s?.plan ?? 'lite',
      clientName: s?.clientName ?? null,
      conversationTurns: s?.conversationTurns ?? 0,
      lastActivity: s?.lastActivity ?? null,
      hasFinancialContext: !!s?.financialContext,
      features: s?.plan ? AI_FEATURES[s.plan] : AI_FEATURES['lite'],
    };
  }
}

// ─── Worker Export (for standalone deployment or service binding) ──────────────

export default {
  async fetch(request: Request, env: AgentEnv): Promise<Response> {
    // Route: /agents/cfo/:agentId/* → CFOAgent
    const url = new URL(request.url);
    const match = url.pathname.match(/^\/agents\/cfo\/([^/]+)(\/.*)?$/);

    if (!match) {
      return Response.json({ error: 'Route not found. Use /agents/cfo/:id/init|chat|analyze|state|reset' }, { status: 404 });
    }

    const agentId = match[1];
    const agentNamespace = (env as any).CFO_AGENT as DurableObjectNamespace;
    const id = agentNamespace.idFromName(agentId);
    const agent = agentNamespace.get(id);

    return agent.fetch(request);
  },
};
