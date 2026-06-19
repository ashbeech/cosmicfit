-- ════════════════════════════════════════════════════════════
-- 002: App Store Server Notifications V2 — subscription events
-- ════════════════════════════════════════════════════════════
-- Append-only audit table for Apple webhook payloads.
-- notification_uuid UNIQUE enforces idempotency at the DB level.
-- RLS enabled with no policies → service role only (Edge Function).
-- Retention: consider pruning rows older than 24 months via pg_cron
-- once data volume warrants it.

CREATE TABLE IF NOT EXISTS public.subscription_events (
    id                      uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    notification_uuid       text        NOT NULL UNIQUE,
    notification_type       text        NOT NULL,
    subtype                 text,
    environment             text        NOT NULL,
    bundle_id               text        NOT NULL,
    original_transaction_id text,
    transaction_id          text,
    product_id              text,
    event_signed_at         timestamptz,
    raw_summary             jsonb       NOT NULL,
    received_at             timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sub_events_original_tx
    ON subscription_events (original_transaction_id)
    WHERE original_transaction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sub_events_received
    ON subscription_events (received_at DESC);

ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
-- No RLS policies: only the service role (Edge Function) can read/write.
