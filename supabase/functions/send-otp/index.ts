import { handleCors } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/supabase-client.ts";
import { errorResponse, jsonResponse } from "../_shared/error-response.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";
import {
  generateOTP,
  hashOTP,
  OTP_TTL_SECONDS,
} from "../_shared/otp-helpers.ts";
import { renderOtpEmail } from "../_shared/otp-email.ts";

type Provider = "resend" | "dev";

const PROVIDER = (Deno.env.get("OTP_EMAIL_PROVIDER") || "resend") as Provider;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const RESEND_FROM =
  Deno.env.get("RESEND_FROM_EMAIL") || "onboarding@resend.dev";

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "Use POST", 405);
  }

  try {
    const { email } = await req.json();

    if (!email || typeof email !== "string") {
      return errorResponse("INVALID_INPUT", "email is required", 400);
    }

    const normalised = email.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalised)) {
      return errorResponse("INVALID_EMAIL", "Not a valid email address", 400);
    }

    const serviceClient = createServiceClient();

    const rateLimited = await checkRateLimit(
      serviceClient,
      `otp:${normalised}`,
      { maxRequests: 3, windowSeconds: 300 },
    );
    if (rateLimited) return rateLimited;

    const code = generateOTP();
    const codeHash = await hashOTP(code);
    const expiresAt = new Date(
      Date.now() + OTP_TTL_SECONDS * 1000,
    ).toISOString();

    await serviceClient
      .from("otp_codes")
      .update({ used_at: new Date().toISOString() })
      .eq("email", normalised)
      .is("used_at", null);

    const { error: insertErr } = await serviceClient.from("otp_codes").insert({
      email: normalised,
      code_hash: codeHash,
      expires_at: expiresAt,
    });

    if (insertErr) {
      console.error("[send-otp] DB insert error:", insertErr.message);
      return errorResponse("DB_ERROR", "Failed to store OTP", 500);
    }

    if (PROVIDER === "resend") {
      if (!RESEND_API_KEY) {
        console.error("[send-otp] RESEND_API_KEY not set");
        return errorResponse(
          "CONFIG_ERROR",
          "Email service not configured",
          500,
        );
      }

      const html = renderOtpEmail(code, normalised);
      const resendResp = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: RESEND_FROM,
          to: [normalised],
          subject: "Your Cosmic Fit login code",
          html,
        }),
      });

      if (!resendResp.ok) {
        const body = await resendResp.text();
        console.error("[send-otp] Resend error:", resendResp.status, body);
        return errorResponse("EMAIL_ERROR", "Failed to send email", 502);
      }

      return jsonResponse({ success: true, provider: "resend" });
    }

    console.log(`[send-otp] DEV MODE — code for ${normalised}: ${code}`);
    return jsonResponse({ success: true, provider: "dev", _devCode: code });
  } catch (e) {
    console.error("[send-otp] Unexpected:", (e as Error).message);
    return errorResponse("INTERNAL", (e as Error).message, 500);
  }
});
