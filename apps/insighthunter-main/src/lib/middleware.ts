
import type { APIContext, MiddlewareNext } from "astro";

export const corsMiddleware = (context: APIContext, next: MiddlewareNext) => {
  const origin = context.request.headers.get("Origin") ?? "*";
  const allowed = origin === "*" || origin.endsWith(".insighthunter.com");

  if (context.request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": allowed ? origin : "",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key",
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  const response = next();
  if (response instanceof Response) {
    response.headers.set("Access-Control-Allow-Origin", allowed ? origin : "");
    response.headers.set("Vary", "Origin");
  }

  return response;
};

export const rateLimitMiddleware = async (context: APIContext, next: MiddlewareNext) => {
  const ip = context.request.headers.get("CF-Connecting-IP") ?? "unknown";
  // Implement rate limiting logic here

  return next();
};

export const authMiddleware = (context: APIContext, next: MiddlewareNext) => {
  const protectedRoutes = ["/dashboard"];
  const { pathname } = context.url;

  if (protectedRoutes.includes(pathname)) {
    const session = context.cookies.get("session");

    if (!session) {
      return context.redirect("https://auth.insighthunter.app");
    }
  }

  return next();
};
