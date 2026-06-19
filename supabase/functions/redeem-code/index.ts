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
    const svc = createServiceClient();

    const body = await req.json().catch(() => null);
    const code = body?.code;
    const clientInstallId = body?.clientInstallId;

    if (!code || typeof code !== "string") {
      return errorResponse("BAD_REQUEST", "Missing 'code' field", 400);
    }
    if (!clientInstallId || typeof clientInstallId !== "string") {
      return errorResponse("BAD_REQUEST", "Missing 'clientInstallId' field", 400);
    }

    const rateLimited = await checkRateLimit(
      svc,
      `redeem-code:${clientInstallId}`,
      { maxRequests: 10, windowSeconds: 60 },
    );
    if (rateLimited) return rateLimited;

    // Extract user_id from JWT if present (optional auth)
    let userId: string | null = null;
    try {
      const userClient = createUserClient(req);
      const { data: { user } } = await userClient.auth.getUser();
      if (user) userId = user.id;
    } catch {
      // No valid session — proceed as guest
    }

    const isDevBuild = body?.isDevBuild === true;

    const { data: result, error: rpcError } = await svc.rpc(
      "redeem_promo_code",
      {
        p_code: code,
        p_client_install_id: clientInstallId,
        p_user_id: userId,
        p_is_dev_build: isDevBuild,
      },
    );

    if (rpcError) {
      return errorResponse("INTERNAL", rpcError.message, 500);
    }

    const rpcResult = result as {
      ok: boolean;
      error?: string;
      alreadyRedeemed?: boolean;
      grant?: { code: string; grantedAt: string; expiresAt: string | null };
    };

    if (!rpcResult.ok) {
      const status = rpcResult.error === "ALREADY_REDEEMED" ? 409 : 400;
      return errorResponse(
        rpcResult.error ?? "INVALID_CODE",
        rpcResult.error === "CODE_EXPIRED"
          ? "This code has expired"
          : "Invalid or exhausted code",
        status,
      );
    }

    return jsonResponse(rpcResult);
  } catch (e) {
    return errorResponse("INTERNAL", (e as Error).message, 500);
  }
});
