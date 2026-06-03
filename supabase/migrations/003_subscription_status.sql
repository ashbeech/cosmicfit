-- ════════════════════════════════════════════════════════════
-- 003: Subscription status ledger (Phase 2)
-- ════════════════════════════════════════════════════════════
-- Tracks the current state of each subscription (keyed by
-- original_transaction_id). Updated from App Store Server
-- Notifications V2 events. Monotonic: only applies status
-- changes whose event_signed_at is newer than the stored
-- last_event_signed_at, preventing out-of-order overwrites.
--
-- RLS enabled, no policies → service role only.

CREATE TYPE public.subscription_status_enum AS ENUM (
    'active',
    'expired',
    'billing_retry',
    'grace_period',
    'revoked',
    'refunded'
);

CREATE TABLE IF NOT EXISTS public.subscription_status (
    original_transaction_id text        PRIMARY KEY,
    status                  public.subscription_status_enum NOT NULL,
    product_id              text        NOT NULL,
    environment             text        NOT NULL,
    bundle_id               text        NOT NULL,
    expires_at              timestamptz,
    last_event_signed_at    timestamptz NOT NULL,
    last_notification_type  text        NOT NULL,
    updated_at              timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sub_status_active
    ON subscription_status (status)
    WHERE status = 'active';

ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;
-- No RLS policies: only the service role (Edge Function) can read/write.

-- Monotonic upsert: only update if the incoming event is newer.
CREATE OR REPLACE FUNCTION upsert_subscription_status(
    p_original_transaction_id text,
    p_status                  public.subscription_status_enum,
    p_product_id              text,
    p_environment             text,
    p_bundle_id               text,
    p_expires_at              timestamptz,
    p_event_signed_at         timestamptz,
    p_notification_type       text
) RETURNS void AS $$
    INSERT INTO public.subscription_status (
        original_transaction_id, status, product_id, environment,
        bundle_id, expires_at, last_event_signed_at, last_notification_type
    ) VALUES (
        p_original_transaction_id, p_status, p_product_id, p_environment,
        p_bundle_id, p_expires_at, p_event_signed_at, p_notification_type
    )
    ON CONFLICT (original_transaction_id) DO UPDATE
        SET status                 = EXCLUDED.status,
            product_id             = EXCLUDED.product_id,
            expires_at             = EXCLUDED.expires_at,
            last_event_signed_at   = EXCLUDED.last_event_signed_at,
            last_notification_type = EXCLUDED.last_notification_type,
            updated_at             = now()
        WHERE EXCLUDED.last_event_signed_at > subscription_status.last_event_signed_at;
$$ LANGUAGE sql;
