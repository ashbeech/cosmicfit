import { handleCors } from "../_shared/cors.ts";
import { createServiceClient, createUserClient } from "../_shared/supabase-client.ts";
import { errorResponse, jsonResponse } from "../_shared/error-response.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";
import { renderFeedbackEmail } from "../_shared/feedback-email.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const FEEDBACK_FROM =
  Deno.env.get("FEEDBACK_FROM_EMAIL") || "noreply@cosmicfit.app";
const FEEDBACK_TO =
  Deno.env.get("FEEDBACK_TO_EMAIL") || "feedback@cosmicfit.app";

const MAX_MESSAGE_LENGTH = 5000;
const MIN_WORD_PATTERN = /\S+\s+\S+/;

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function stripControlChars(str: string): string {
  return str.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "");
}

function getClientIp(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) return forwarded.split(",")[0].trim();
  return req.headers.get("x-real-ip") || "unknown";
}

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "Use POST", 405);
  }

  try {
    // Authenticate
    const userClient = createUserClient(req);
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return errorResponse("UNAUTHORIZED", "Authentication required", 401);
    }

    const userId = user.id;
    const userEmail = user.email || null;
    const clientIp = getClientIp(req);

    console.log(`[send-feedback] request userId=${userId} ip=${clientIp}`);

    // Parse body
    const body = await req.json();
    const { message, metadata } = body;

    if (!message || typeof message !== "string") {
      return errorResponse("INVALID_INPUT", "message is required", 400);
    }

    const trimmed = message.trim().replace(/\s+/g, " ").slice(0, MAX_MESSAGE_LENGTH + 1);

    if (trimmed.length > MAX_MESSAGE_LENGTH) {
      return errorResponse("MESSAGE_TOO_LONG", `Message must be ${MAX_MESSAGE_LENGTH} characters or fewer`, 400);
    }

    if (trimmed.length < 3) {
      return errorResponse("MESSAGE_TOO_SHORT", "Message is too short", 400);
    }

    if (!MIN_WORD_PATTERN.test(trimmed)) {
      return errorResponse("MESSAGE_TOO_SHORT", "Please enter at least two words", 400);
    }

    // Validate metadata
    let displayDate: string | null = null;
    let deviceModel: string | null = null;
    let iosVersion: string | null = null;
    let appVersion: string | null = null;

    if (metadata && typeof metadata === "object") {
      const allowed = ["displayDate", "deviceModel", "iosVersion", "appVersion"];
      for (const key of Object.keys(metadata)) {
        if (!allowed.includes(key)) {
          return errorResponse("INVALID_INPUT", `Unknown metadata field: ${key}`, 400);
        }
      }
      const clean = (val: unknown): string | null => {
        if (typeof val !== "string") return null;
        const s = stripControlChars(val.trim());
        return s.length > 0 && s.length <= 200 ? s : null;
      };
      displayDate = clean(metadata.displayDate);
      deviceModel = clean(metadata.deviceModel);
      iosVersion = clean(metadata.iosVersion);
      appVersion = clean(metadata.appVersion);
    }

    // Rate limit: per user
    const serviceClient = createServiceClient();

    const userRateLimited = await checkRateLimit(
      serviceClient,
      `feedback:user:${userId}`,
      { maxRequests: 10, windowSeconds: 3600 },
    );
    if (userRateLimited) {
      console.log(`[send-feedback] rate_limited key=feedback:user:${userId}`);
      return userRateLimited;
    }

    // Rate limit: per IP
    const ipRateLimited = await checkRateLimit(
      serviceClient,
      `feedback:ip:${clientIp}`,
      { maxRequests: 30, windowSeconds: 3600 },
    );
    if (ipRateLimited) {
      console.log(`[send-feedback] rate_limited key=feedback:ip:${clientIp}`);
      return ipRateLimited;
    }

    // Send email via Resend
    if (!RESEND_API_KEY) {
      console.error("[send-feedback] RESEND_API_KEY not set");
      return errorResponse("CONFIG_ERROR", "Email service not configured", 500);
    }

    const html = renderFeedbackEmail({
      message: escapeHtml(trimmed),
      userEmail,
      userId,
      displayDate,
      deviceModel,
      iosVersion,
      appVersion,
    });

    const subject = displayDate
      ? `Cosmic Fit Feedback \u2014 ${displayDate}`
      : "Cosmic Fit Feedback \u2014 Daily Fit";

    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FEEDBACK_FROM,
        to: [FEEDBACK_TO],
        reply_to: userEmail || undefined,
        subject,
        html,
      }),
    });

    if (!resendResp.ok) {
      const respBody = await resendResp.text();
      console.error(`[send-feedback] error code=EMAIL_SEND_FAILED status=${resendResp.status} body=${respBody}`);
      return errorResponse("EMAIL_SEND_FAILED", "Failed to send feedback", 502);
    }

    const resendData = await resendResp.json();
    console.log(`[send-feedback] sent userId=${userId} resendId=${resendData.id ?? "unknown"}`);

    return jsonResponse({ success: true });
  } catch (e) {
    console.error("[send-feedback] error code=INTERNAL_ERROR", (e as Error).message);
    return errorResponse("INTERNAL_ERROR", "An unexpected error occurred", 500);
  }
});
