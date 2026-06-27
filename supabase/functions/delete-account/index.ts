import { handleCors } from "../_shared/cors.ts";
import {
  createServiceClient,
  createUserClient,
} from "../_shared/supabase-client.ts";
import { errorResponse, jsonResponse } from "../_shared/error-response.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "POST required", 405);
  }

  try {
    const userClient = createUserClient(req);
    const {
      data: { user },
      error: userErr,
    } = await userClient.auth.getUser();

    if (userErr || !user) {
      return errorResponse("UNAUTHORIZED", "Authentication required", 401);
    }

    const svc = createServiceClient();

    const rateLimited = await checkRateLimit(
      svc,
      `delete-account:${user.id}`,
      { maxRequests: 3, windowSeconds: 3600 },
    );
    if (rateLimited) return rateLimited;

    // Detach user from promo_redemptions and expire grants to avoid FK violation
    // on auth.users delete. Rows are preserved for audit; the user link is severed
    // and grant_expires_at is set to now so orphaned rows cannot leak comp access
    // to the next user on the same device.
    const { error: promoErr } = await svc
      .from("promo_redemptions")
      .update({ user_id: null, grant_expires_at: new Date().toISOString() })
      .eq("user_id", user.id);

    if (promoErr) {
      console.error("[delete-account] promo detach error:", promoErr.message);
      return errorResponse("INTERNAL", "Failed to prepare account for deletion", 500);
    }

    const { error: deleteErr } = await svc.auth.admin.deleteUser(user.id);
    if (deleteErr) {
      console.error("[delete-account] deleteUser error:", deleteErr.message);
      return errorResponse("INTERNAL", "Failed to delete account", 500);
    }

    return jsonResponse({ success: true });
  } catch (e) {
    console.error("[delete-account] Unexpected:", (e as Error).message);
    return errorResponse("INTERNAL", (e as Error).message, 500);
  }
});
