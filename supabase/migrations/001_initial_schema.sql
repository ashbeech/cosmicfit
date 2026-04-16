-- ════════════════════════════════════════════════════════════
-- Cosmic Fit: Full Database Schema
-- ════════════════════════════════════════════════════════════
-- Source: BLUEPRINT_REBUILD_SPEC_v2.3.md (WP5). Portable: can be
-- pasted into the Supabase SQL editor or applied via `supabase db push`.
--
-- Notes:
-- • pg_cron is available on hosted Supabase Pro+; on Free tier or some
--   local setups, `CREATE EXTENSION pg_cron` or `cron.schedule` may
--   fail — comment out section 5 and run prune jobs manually if needed.
-- • Trigger syntax uses EXECUTE FUNCTION (Postgres 14+).

-- 0. Required Extensions
-- ────────────────────────────────────────────────────────────
-- pgcrypto: provides gen_random_uuid() used for primary keys.
-- Supabase enables this by default, but include explicitly for portability.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- pg_cron: provides cron.schedule() used for scheduled cleanup jobs (§5 below).
-- On Supabase, pg_cron is available on Pro plan and above.
-- On self-hosted Postgres, install pg_cron extension separately.
-- If pg_cron is NOT available, the scheduled jobs in §5 will fail silently —
-- you must run the prune functions manually or via an external scheduler.
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ────────────────────────────────────────────────────────────
-- Infrastructure assumptions:
--   • Postgres 14+ (for gen_random_uuid() without pgcrypto on PG13+, but we include pgcrypto for safety)
--   • Supabase project with Auth enabled (auth.users table exists)
--   • Supabase Pro plan if using pg_cron (free tier does not include pg_cron)
--   • If deploying outside Supabase: ensure auth.users table/schema exists or adapt triggers
-- ────────────────────────────────────────────────────────────

-- 1. Tables
-- ────────────────────────────────────────────────────────────

-- 1a. profiles (extended user data, auto-created on signup)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    first_name text NOT NULL,
    birth_date timestamptz NOT NULL,
    birth_location text NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    timezone_identifier text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 1b. user_preferences (app settings that sync between devices)
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    has_seen_welcome boolean DEFAULT false,
    notification_enabled boolean DEFAULT false,
    updated_at timestamptz DEFAULT now()
);

-- 1c. user_blueprints (cached Blueprint for cross-device sync)
CREATE TABLE IF NOT EXISTS public.user_blueprints (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    blueprint_json jsonb NOT NULL,
    engine_version text NOT NULL,
    generated_at timestamptz DEFAULT now(),
    UNIQUE(user_id)
);

-- 1d. otp_codes (custom OTP flow)
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    email text NOT NULL,
    code_hash text NOT NULL,
    attempts int DEFAULT 0,
    max_attempts int DEFAULT 3,
    expires_at timestamptz NOT NULL,
    used_at timestamptz,
    created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_otp_active ON otp_codes (email, expires_at DESC)
    WHERE used_at IS NULL;

-- 1e. rate_limit_hits (persistent rate-limit tracking)
CREATE TABLE IF NOT EXISTS public.rate_limit_hits (
    key text NOT NULL,
    "window" timestamptz NOT NULL,
    count integer NOT NULL DEFAULT 1,
    PRIMARY KEY (key, "window")
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_hits_window
    ON rate_limit_hits("window");


-- 2. Functions
-- ────────────────────────────────────────────────────────────

-- 2a. Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, first_name, birth_date, birth_location, latitude, longitude, timezone_identifier)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'first_name', ''),
        COALESCE((NEW.raw_user_meta_data ->> 'birth_date')::timestamptz, now()),
        COALESCE(NEW.raw_user_meta_data ->> 'birth_location', ''),
        COALESCE((NEW.raw_user_meta_data ->> 'latitude')::double precision, 0.0),
        COALESCE((NEW.raw_user_meta_data ->> 'longitude')::double precision, 0.0),
        COALESCE(NEW.raw_user_meta_data ->> 'timezone_identifier', 'UTC')
    );
    INSERT INTO public.user_preferences (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2b. updated_at trigger helper
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2c. Atomic rate-limit check
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_key text,
    p_window timestamptz,
    p_max int
) RETURNS boolean AS $$
    INSERT INTO rate_limit_hits (key, "window", count)
    VALUES (p_key, p_window, 1)
    ON CONFLICT (key, "window")
        DO UPDATE SET count = rate_limit_hits.count + 1
    RETURNING count <= p_max;
$$ LANGUAGE sql;

-- 2d. Prune old rate-limit hits
CREATE OR REPLACE FUNCTION prune_rate_limit_hits() RETURNS void AS $$
    DELETE FROM rate_limit_hits
    WHERE "window" < now() - INTERVAL '10 minutes';
$$ LANGUAGE sql;


-- 3. Triggers
-- ────────────────────────────────────────────────────────────

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- 4. Row Level Security
-- ────────────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = id);

ALTER TABLE public.user_blueprints ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own blueprint" ON public.user_blueprints
    FOR ALL USING (auth.uid() = user_id);

-- otp_codes: service role only, no public policies
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- rate_limit_hits: service role only, no public policies
ALTER TABLE public.rate_limit_hits ENABLE ROW LEVEL SECURITY;


-- 5. Scheduled Jobs (pg_cron)
-- ────────────────────────────────────────────────────────────

-- Prune rate_limit_hits older than 10 min -- every 2 minutes
SELECT cron.schedule(
    'prune-rate-limit-hits',
    '*/2 * * * *',
    $$SELECT prune_rate_limit_hits()$$
);

-- Prune expired OTP codes older than 1 hour -- every 10 minutes
SELECT cron.schedule(
    'prune-expired-otp-codes',
    '*/10 * * * *',
    $$DELETE FROM otp_codes WHERE expires_at < now() - interval '1 hour'$$
);
