import { handleCors } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/supabase-client.ts";
import { errorResponse, jsonResponse } from "../_shared/error-response.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "Use POST", 405);
  }

  try {
    const { email, profile } = await req.json();

    if (!email || typeof email !== "string") {
      return errorResponse("INVALID_INPUT", "email is required", 400);
    }

    if (!profile || typeof profile !== "object") {
      return errorResponse("INVALID_INPUT", "profile is required", 400);
    }

    const normalised = email.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalised)) {
      return errorResponse("INVALID_EMAIL", "Not a valid email address", 400);
    }

    const {
      first_name,
      birth_date,
      birth_location,
      latitude,
      longitude,
      timezone_identifier,
      birth_time_is_unknown,
    } = profile;

    if (!first_name || !birth_date || !birth_location || latitude == null || longitude == null || !timezone_identifier) {
      return errorResponse("INVALID_INPUT", "profile fields are incomplete", 400);
    }

    const serviceClient = createServiceClient();

    const rateLimited = await checkRateLimit(
      serviceClient,
      `signup:${normalised}`,
      { maxRequests: 5, windowSeconds: 3600 },
    );
    if (rateLimited) return rateLimited;

    // Attempt to create user — if "already exists" return EMAIL_EXISTS
    const { data: newUser, error: createErr } =
      await serviceClient.auth.admin.createUser({
        email: normalised,
        email_confirm: true,
      });

    if (createErr) {
      const msg = createErr.message ?? "";
      if (msg.includes("already") || msg.includes("exists")) {
        return errorResponse(
          "EMAIL_EXISTS",
          "An account with this email already exists. Please sign in with a verification code.",
          409,
        );
      }
      console.error("[signup-with-profile] createUser error:", msg);
      return errorResponse("AUTH_ERROR", "Failed to create account", 500);
    }

    const userId = newUser?.user?.id;
    if (!userId) {
      console.error("[signup-with-profile] createUser returned no user id");
      return errorResponse("AUTH_ERROR", "Failed to create account", 500);
    }

    // Upsert profile with real birth data (handle_new_user trigger creates stub row)
    const { error: upsertErr } = await serviceClient
      .from("profiles")
      .upsert(
        {
          id: userId,
          first_name,
          birth_date,
          birth_location,
          latitude,
          longitude,
          timezone_identifier,
          birth_time_is_unknown: birth_time_is_unknown ?? false,
        },
        { onConflict: "id" },
      );

    if (upsertErr) {
      console.error("[signup-with-profile] profile upsert error:", upsertErr.message);
    }

    // Issue session (same pattern as verify-otp)
    const { data: linkData, error: linkErr } =
      await serviceClient.auth.admin.generateLink({
        type: "magiclink",
        email: normalised,
      });

    if (linkErr || !linkData) {
      console.error("[signup-with-profile] generateLink error:", linkErr?.message);
      return errorResponse("AUTH_ERROR", "Failed to create session", 500);
    }

    const tokenHash =
      linkData.properties?.hashed_token ??
      (linkData as Record<string, unknown>).hashed_token;

    if (!tokenHash) {
      console.error("[signup-with-profile] No hashed_token in generateLink response");
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
        "[signup-with-profile] token exchange failed:",
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
    });
  } catch (e) {
    console.error("[signup-with-profile] Unexpected:", (e as Error).message);
    return errorResponse("INTERNAL", (e as Error).message, 500);
  }
});
