import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "./cors.ts";

export interface RateLimitOptions {
  maxRequests: number;
  windowSeconds: number;
}

const DEFAULT_OPTIONS: RateLimitOptions = {
  maxRequests: 60,
  windowSeconds: 60,
};

export async function checkRateLimit(
  client: SupabaseClient,
  key: string,
  options: Partial<RateLimitOptions> = {}
): Promise<Response | null> {
  const { maxRequests, windowSeconds } = { ...DEFAULT_OPTIONS, ...options };

  const windowMs = windowSeconds * 1000;
  const windowStart = new Date(
    Math.floor(Date.now() / windowMs) * windowMs
  ).toISOString();

  const { data: allowed, error } = await client.rpc("check_rate_limit", {
    p_key: key,
    p_window: windowStart,
    p_max: maxRequests,
  });

  if (error) {
    console.error("[rate-limit] RPC error, failing open:", error.message);
    return null;
  }

  if (allowed === false) {
    const retryAfter = Math.ceil(windowSeconds);
    return new Response(
      JSON.stringify({
        error: { code: "RATE_LIMITED", message: "Too many requests. Please try again later." },
      }),
      {
        status: 429,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Retry-After": String(retryAfter),
        },
      }
    );
  }

  return null;
}
