import { createServiceClient } from "../_shared/supabase-client.ts";
import { errorResponse, jsonResponse } from "../_shared/error-response.ts";
import {
  verifyAndDecodeNotification,
  VerificationError,
} from "../_shared/app-store-jws.ts";
import type { VerifiedNotification } from "../_shared/app-store-jws.ts";

const BUNDLE_ID = Deno.env.get("APP_STORE_BUNDLE_ID");
const APP_APPLE_ID = Deno.env.get("APP_APPLE_ID");
const ALLOWED_PRODUCT_IDS = [
  "com.cosmicfit.full.monthly",
  "com.cosmicfit.full.annual",
];

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "Use POST", 405);
  }

  if (!BUNDLE_ID) {
    console.error(JSON.stringify({
      level: "error",
      event: "app_store_config_missing",
      detail: "APP_STORE_BUNDLE_ID secret is not set",
    }));
    return errorResponse("CONFIG_ERROR", "Server misconfigured", 500);
  }

  let body: { signedPayload?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse("INVALID_BODY", "Expected JSON with signedPayload", 400);
  }

  if (!body.signedPayload || typeof body.signedPayload !== "string") {
    return errorResponse("MISSING_PAYLOAD", "signedPayload is required", 400);
  }

  let notification: VerifiedNotification;
  try {
    notification = await verifyAndDecodeNotification(body.signedPayload, {
      bundleId: BUNDLE_ID,
      appAppleId: APP_APPLE_ID ?? undefined,
      allowedProductIds: ALLOWED_PRODUCT_IDS,
    });
  } catch (err) {
    if (err instanceof VerificationError) {
      console.error(JSON.stringify({
        level: "warn",
        event: "app_store_notification_rejected",
        reason: err.message,
      }));
      return errorResponse("VERIFICATION_FAILED", err.message, 400);
    }
    console.error(JSON.stringify({
      level: "error",
      event: "app_store_notification_verify_error",
      error: (err as Error).message,
    }));
    return errorResponse("INTERNAL_ERROR", "Verification failed", 500);
  }

  console.log(JSON.stringify({
    level: "info",
    event: "app_store_notification_verified",
    notificationUUID: notification.notificationUUID,
    notificationType: notification.notificationType,
    subtype: notification.subtype,
    environment: notification.environment,
    productId: notification.productId,
    originalTransactionId: notification.originalTransactionId,
  }));

  const db = createServiceClient();
  const { error: dbError } = await db.from("subscription_events").upsert(
    {
      notification_uuid: notification.notificationUUID,
      notification_type: notification.notificationType,
      subtype: notification.subtype ?? null,
      environment: notification.environment,
      bundle_id: notification.bundleId,
      original_transaction_id: notification.originalTransactionId ?? null,
      transaction_id: notification.transactionId ?? null,
      product_id: notification.productId ?? null,
      event_signed_at: notification.eventSignedAt ?? null,
      raw_summary: {
        notificationType: notification.notificationType,
        subtype: notification.subtype ?? null,
        environment: notification.environment,
        bundleId: notification.bundleId,
        appAppleId: notification.appAppleId ?? null,
        productId: notification.productId ?? null,
        originalTransactionId: notification.originalTransactionId ?? null,
        transactionId: notification.transactionId ?? null,
        eventSignedAt: notification.eventSignedAt ?? null,
      },
    },
    { onConflict: "notification_uuid", ignoreDuplicates: true },
  );

  if (dbError) {
    console.error(JSON.stringify({
      level: "error",
      event: "app_store_notification_db_error",
      notificationUUID: notification.notificationUUID,
      error: dbError.message,
    }));
    return errorResponse("DB_ERROR", "Failed to persist notification", 500);
  }

  // Phase 2: update subscription_status via monotonic upsert (if applicable)
  const status = mapNotificationToStatus(notification.notificationType, notification.subtype);
  if (status && notification.originalTransactionId && notification.productId && notification.eventSignedAt) {
    const { error: statusErr } = await db.rpc("upsert_subscription_status", {
      p_original_transaction_id: notification.originalTransactionId,
      p_status: status,
      p_product_id: notification.productId,
      p_environment: notification.environment,
      p_bundle_id: notification.bundleId,
      p_expires_at: null,
      p_event_signed_at: notification.eventSignedAt,
      p_notification_type: notification.notificationType,
    });

    if (statusErr) {
      // Non-fatal: audit row already persisted; log but still return 200
      console.error(JSON.stringify({
        level: "warn",
        event: "app_store_status_upsert_error",
        notificationUUID: notification.notificationUUID,
        error: statusErr.message,
      }));
    }
  }

  return jsonResponse({ ok: true });
});

// Maps V2 notification types to subscription_status_enum values.
// Returns undefined for types that don't represent a status change.
function mapNotificationToStatus(
  type: string,
  subtype: string | undefined,
): string | undefined {
  switch (type) {
    case "SUBSCRIBED":
    case "DID_RENEW":
    case "RENEWAL_EXTENDED":
      return "active";
    case "EXPIRED":
    case "DID_CHANGE_RENEWAL_STATUS":
      return subtype === "AUTO_RENEW_DISABLED" ? "active" : "expired";
    case "DID_FAIL_TO_RENEW":
      return subtype === "GRACE_PERIOD" ? "grace_period" : "billing_retry";
    case "GRACE_PERIOD_EXPIRED":
      return "billing_retry";
    case "REFUND":
      return "refunded";
    case "REVOKE":
      return "revoked";
    default:
      return undefined;
  }
}
