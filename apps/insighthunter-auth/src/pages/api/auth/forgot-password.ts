// apps/insighthunter-auth/src/pages/api/auth/forgot-password.ts
import type { APIRoute } from 'astro';
import { checkRateLimit, signEmailJWT, auditLog } from '../../../lib/auth';
import { sendEmail } from '../../../lib/email'; // swap to lib/auth if using Resend

export const POST: APIRoute = async ({ request, locals, clientAddress }) => {
  const env = locals.runtime.env;

  try {
    const { email } = await request.json() as { email: string };
    if (!email) return err('Email is required', 400);

    const ip   = clientAddress ?? request.headers.get('CF-Connecting-IP') ?? 'unknown';

    // Rate limit: 3 reset requests per IP per 15 min
    const rate = await checkRateLimit(env.RATE_LIMIT, `reset:${ip}`, 3, 900);
    if (!rate.allowed) return err('Too many requests. Please wait 15 minutes.', 429);

    // Always return 200 — prevents user enumeration
    const user = await env.DB.prepare(
      `SELECT id, email FROM users WHERE email = ? AND email_verified = 1`
    ).bind(email.toLowerCase()).first<{ id: string; email: string }>();

    if (user) {
      const token     = await signEmailJWT(user.email, env.VERIFY_EMAIL_JWT_SECRET, '15m');
      const resetUrl  = `https://${env.APP_DOMAIN}/auth/reset-password?token=${token}`;

      await sendEmail(
        env,
        user.email,
        `Reset your ${env.APP_NAME} password`,
        resetEmailHtml(env.APP_NAME, resetUrl)
      );

      auditLog(env, 'password_reset_requested', user.id, ip,
        request.headers.get('user-agent') ?? '');
    }

    // Same response whether user exists or not
    return new Response(JSON.stringify({
      success: true,
      message: 'If an account exists for that email, a reset link has been sent.'
    }), { status: 200, headers: { 'Content-Type': 'application/json' } });

  } catch (e) {
    console.error('Forgot password error:', e);
    return err('An unexpected error occurred.', 500);
  }
};

function resetEmailHtml(appName: string, resetUrl: string): string {
  return `
    <div style="font-family:Inter,sans-serif;max-width:480px;margin:0 auto;padding:2rem">
      <h2 style="color:#111827">Reset your password</h2>
      <p style="color:#4b5563">We received a request to reset your ${appName} password.
         Click the button below. This link expires in <strong>15 minutes</strong>.</p>
      <a href="${resetUrl}"
         style="display:inline-block;background:#007aff;color:#fff;padding:.75rem 1.5rem;
                border-radius:8px;text-decoration:none;font-weight:500;margin:1rem 0">
        Reset Password
      </a>
      <p style="color:#9ca3af;font-size:.875rem">
        If you didn't request this, you can safely ignore this email.
        Your password will not change.
      </p>
    </div>`;
}

const err = (message: string, status: number) =>
  new Response(JSON.stringify({ error: message }), {
    status, headers: { 'Content-Type': 'application/json' },
  });
