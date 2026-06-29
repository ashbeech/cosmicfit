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
    const clientInstallId = body?.clientInstallId;

    if (!clientInstallId || typeof clientInstallId !== "string") {
      return errorResponse("BAD_REQUEST", "Missing 'clientInstallId' field", 400);
    }

    const rateLimited = await checkRateLimit(
      svc,
      `check-comp:${clientInstallId}`,
      { maxRequests: 30, windowSeconds: 60 },
    );
    if (rateLimited) return rateLimited;

    let userId: string | null = null;
    try {
      const userClient = createUserClient(req);
      const { data: { user } } = await userClient.auth.getUser();
      if (user) userId = user.id;
    } catch {
      // No valid session — proceed as guest
    }

    const { data: result, error: rpcError } = await svc.rpc(
      "get_comp_access",
      {
        p_client_install_id: clientInstallId,
        p_user_id: userId,
      },
    );

    if (rpcError) {
      return errorResponse("INTERNAL", rpcError.message, 500);
    }

    // #region agent log
    const r = result as Record<string, unknown>;
    const g = r?.grant as Record<string, unknown> | undefined;
    console.log(`[check-comp-access][debug-3a0123] userId=${userId ?? 'guest'} installId=${clientInstallId.slice(0,8)}… hasAccess=${r?.hasCompAccess ?? false} slot=${g?.redemptionPosition ?? 'none'}`);
    // #endregion

    return jsonResponse(result);
  } catch (e) {
    return errorResponse("INTERNAL", (e as Error).message, 500);
  }
});
