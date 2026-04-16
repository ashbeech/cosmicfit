import { handleCors } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/supabase-client.ts";
import { errorResponse, jsonResponse } from "../_shared/error-response.ts";
import { hashOTP, OTP_MAX_ATTEMPTS } from "../_shared/otp-helpers.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "Use POST", 405);
  }

  try {
    const { email, code } = await req.json();

    if (!email || !code) {
      return errorResponse("INVALID_INPUT", "email and code are required", 400);
    }

    const normalised = String(email).trim().toLowerCase();
    const trimmedCode = String(code).trim();

    const serviceClient = createServiceClient();

    const { data: otp, error: fetchErr } = await serviceClient
      .from("otp_codes")
      .select("id, code_hash, attempts, max_attempts, expires_at")
      .eq("email", normalised)
      .is("used_at", null)
      .gt("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (fetchErr) {
      console.error("[verify-otp] DB fetch error:", fetchErr.message);
      return errorResponse("DB_ERROR", "Verification failed", 500);
    }

    if (!otp) {
      return errorResponse(
        "CODE_EXPIRED",
        "No active code found. Please request a new one.",
        400,
      );
    }

    if (otp.attempts >= (otp.max_attempts ?? OTP_MAX_ATTEMPTS)) {
      await serviceClient
        .from("otp_codes")
        .update({ used_at: new Date().toISOString() })
        .eq("id", otp.id);

      return errorResponse(
        "TOO_MANY_ATTEMPTS",
        "Too many incorrect attempts. Please request a new code.",
        429,
      );
    }

    const inputHash = await hashOTP(trimmedCode);

    if (inputHash !== otp.code_hash) {
      await serviceClient
        .from("otp_codes")
        .update({ attempts: otp.attempts + 1 })
        .eq("id", otp.id);

      const remaining =
        (otp.max_attempts ?? OTP_MAX_ATTEMPTS) - otp.attempts - 1;
      return errorResponse(
        "INVALID_CODE",
        remaining > 0
          ? `Incorrect code. ${remaining} attempt${remaining === 1 ? "" : "s"} remaining.`
          : "Incorrect code. Please request a new one.",
        400,
      );
    }

    await serviceClient
      .from("otp_codes")
      .update({ used_at: new Date().toISOString() })
      .eq("id", otp.id);

    const { error: createErr } = await serviceClient.auth.admin.createUser({
      email: normalised,
      email_confirm: true,
    });

    if (createErr) {
      const msg = createErr.message ?? "";
      if (!msg.includes("already") && !msg.includes("exists")) {
        console.error("[verify-otp] createUser error:", msg);
        return errorResponse("AUTH_ERROR", "Failed to provision user", 500);
      }
    }

    const { data: linkData, error: linkErr } =
      await serviceClient.auth.admin.generateLink({
        type: "magiclink",
        email: normalised,
      });

    if (linkErr || !linkData) {
      console.error("[verify-otp] generateLink error:", linkErr?.message);
      return errorResponse("AUTH_ERROR", "Failed to create session link", 500);
    }

    const tokenHash =
      linkData.properties?.hashed_token ??
      (linkData as Record<string, unknown>).hashed_token;

    if (!tokenHash) {
      console.error("[verify-otp] No hashed_token in generateLink response");
      return errorResponse("AUTH_ERROR", "Session creation failed", 500);
    }

    const verifyResp = await fetch(`${SUPABASE_URL}/auth/v1/verify`, {
      method: "POST",
      headers: {
        apikey: ANON_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        token_hash: tokenHash,
        type: "magiclink",
      }),
    });

    if (!verifyResp.ok) {
      const body = await verifyResp.text();
      console.error(
        "[verify-otp] token exchange failed:",
        verifyResp.status,
        body,
      );
      return errorResponse("AUTH_ERROR", "Session creation failed", 500);
    }

    const session = await verifyResp.json();

    return jsonResponse({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      user: session.user,
    });
  } catch (e) {
    console.error("[verify-otp] Unexpected:", (e as Error).message);
    return errorResponse("INTERNAL", (e as Error).message, 500);
  }
});
