-- ════════════════════════════════════════════════════════════
-- Cosmic Fit: Content Dashboard schema  (migration 012)
-- ════════════════════════════════════════════════════════════
-- Source of truth: docs/handoff/content_dashboard_plan.md
--
-- Copy-paste-ready: paste this whole file into the Supabase SQL editor
-- (Dashboard → SQL Editor → New query → Run). Safe to run once on the
-- existing project; every object is dash_-prefixed and additive.
--
-- Conventions mirror supabase/migrations/001_initial_schema.sql:
--   • pgcrypto / gen_random_uuid() for uuid PKs
--   • timestamptz DEFAULT now()
--   • RLS ENABLED with NO policies  ⇒  deny-all through PostgREST.
--     Only the server's SERVICE-ROLE key (which bypasses RLS) may read or
--     write these tables. A leaked anon/publishable key can touch nothing.
--
-- NOT included (v1, per plan): pg_trgm / tsvector / FTS — search is
-- client-side fuzzy. pg_cron is used only for an OPTIONAL prune job, wrapped
-- so the migration still succeeds on Free tier where pg_cron is absent.
--
-- After running this: create the Storage bucket `dash-baselines` (Private),
-- then `npm run seed && npm run seed:users`.

-- 0. Extensions
-- ────────────────────────────────────────────────────────────
-- pgcrypto: gen_random_uuid(). Supabase enables it by default; explicit for portability.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- 1. Tables
-- ────────────────────────────────────────────────────────────

-- 1a. dash_users — the two operators (maria, ash). No email; argon2id hash.
CREATE TABLE IF NOT EXISTS public.dash_users (
    id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    username      text NOT NULL UNIQUE,
    password_hash text NOT NULL,               -- argon2id
    display_name  text NOT NULL,
    created_at    timestamptz DEFAULT now()
);

-- 1b. dash_baseline — one row per imported content-file version.
-- Large files (blueprint, ~10.6 MB) live in Storage bucket `dash-baselines`
-- and set storage_path (tree stays NULL). Small files (TarotCards) store the
-- parsed tree inline in `tree` (storage_path NULL). Read only at seed/export.
CREATE TABLE IF NOT EXISTS public.dash_baseline (
    version_id   uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    repo_path    text NOT NULL,                -- canonical repo path this baseline reconstructs
    storage_path text,                         -- object path in `dash-baselines` (large files)
    sha256       text NOT NULL,                -- of the exact committed bytes
    byte_size    bigint NOT NULL,
    tree         jsonb,                         -- inline parsed tree (small files only)
    imported_at  timestamptz DEFAULT now(),
    CHECK (storage_path IS NOT NULL OR tree IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_dash_baseline_repo_path
    ON public.dash_baseline (repo_path, imported_at DESC);

-- 1c. dash_field — the editable-field registry, derived at seed time.
-- Holds baseline_value so rendering + search never load the big blob.
CREATE TABLE IF NOT EXISTS public.dash_field (
    id                  uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    file                text NOT NULL,          -- 'blueprint' | 'tarot' (astro deferred to v2)
    field_path          text NOT NULL,          -- RFC-6901 JSON pointer into the baseline tree
    natural_key         text NOT NULL,          -- human-readable, stable across reseed (re-anchor key)
    group_key           text NOT NULL,          -- cluster key / card name  (nav grouping)
    section_key         text,                   -- section/sub-field within the group
    field_kind          text NOT NULL,          -- 'paragraph' | 'intro' | 'closing' | 'prose'
    baseline_value      text,                   -- baseline prose at this pointer (search/render source)
    baseline_version_id uuid REFERENCES public.dash_baseline (version_id),
    -- blueprint facet columns (parsed from group_key; NULL for other files)
    venus_sign          text,
    moon_sign           text,
    element             text,
    created_at          timestamptz DEFAULT now(),
    UNIQUE (file, field_path)
);

CREATE INDEX IF NOT EXISTS idx_dash_field_group   ON public.dash_field (file, group_key);
CREATE INDEX IF NOT EXISTS idx_dash_field_facets  ON public.dash_field (venus_sign, moon_sign, element);

-- 1d. dash_override — the current edited value for a field (absent ⇒ baseline).
CREATE TABLE IF NOT EXISTS public.dash_override (
    field_id      uuid PRIMARY KEY REFERENCES public.dash_field (id) ON DELETE CASCADE,
    current_value text NOT NULL,
    version       int  NOT NULL DEFAULT 1,      -- optimistic-concurrency counter
    updated_by    text NOT NULL,
    updated_at    timestamptz DEFAULT now()
);

-- 1e. dash_edit_log — append-only history (per-field history + global feed + restores).
CREATE TABLE IF NOT EXISTS public.dash_edit_log (
    id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    field_id   uuid NOT NULL REFERENCES public.dash_field (id) ON DELETE CASCADE,
    field_path text NOT NULL,
    file       text NOT NULL,
    group_key  text NOT NULL,
    old_value  text,                            -- value before this write (NULL = was baseline)
    new_value  text NOT NULL,
    version    int  NOT NULL,
    edited_by  text NOT NULL,
    edited_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dash_edit_log_field ON public.dash_edit_log (field_id, edited_at DESC);
CREATE INDEX IF NOT EXISTS idx_dash_edit_log_feed  ON public.dash_edit_log (edited_at DESC);

-- 1f. dash_content_versions — one row per Export (the "which version did I download").
CREATE TABLE IF NOT EXISTS public.dash_content_versions (
    version_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at          timestamptz DEFAULT now(),
    editor              text NOT NULL,
    label               text,
    manifest            jsonb NOT NULL,
    file_sha256         jsonb NOT NULL,
    changed_field_count int  NOT NULL DEFAULT 0,
    status              text NOT NULL DEFAULT 'exported'
);

-- 1g. dash_login_attempts — persistent brute-force guard.
-- Composite PK (mirrors rate_limit_hits in 001) so the atomic upsert below
-- survives serverless cold starts — an in-memory counter would not.
CREATE TABLE IF NOT EXISTS public.dash_login_attempts (
    attempt_key  text NOT NULL,                 -- 'username|ip'
    window_start timestamptz NOT NULL,
    count        int NOT NULL DEFAULT 1,
    PRIMARY KEY (attempt_key, window_start)
);

CREATE INDEX IF NOT EXISTS idx_dash_login_attempts_window
    ON public.dash_login_attempts (window_start);


-- 2. Functions
-- ────────────────────────────────────────────────────────────

-- 2a. Persistent login rate-limit — count failures per rolling window.
-- Read-only current-window count (checked BEFORE verifying the password).
CREATE OR REPLACE FUNCTION public.dash_login_failure_count(
    p_attempt_key    text,
    p_window_seconds int DEFAULT 900
) RETURNS int AS $$
    SELECT COALESCE(count, 0)
    FROM public.dash_login_attempts
    WHERE attempt_key = p_attempt_key
      AND window_start = to_timestamp(floor(extract(epoch FROM now()) / p_window_seconds) * p_window_seconds);
$$ LANGUAGE sql;

-- Atomic increment on a failed login; returns the new count for this window.
CREATE OR REPLACE FUNCTION public.dash_register_login_failure(
    p_attempt_key    text,
    p_window_seconds int DEFAULT 900
) RETURNS int AS $$
    INSERT INTO public.dash_login_attempts (attempt_key, window_start, count)
    VALUES (
        p_attempt_key,
        to_timestamp(floor(extract(epoch FROM now()) / p_window_seconds) * p_window_seconds),
        1
    )
    ON CONFLICT (attempt_key, window_start)
        DO UPDATE SET count = public.dash_login_attempts.count + 1
    RETURNING count;
$$ LANGUAGE sql;

-- Clear a key's failures after a successful login.
CREATE OR REPLACE FUNCTION public.dash_clear_login_failures(p_attempt_key text)
RETURNS void AS $$
    DELETE FROM public.dash_login_attempts WHERE attempt_key = p_attempt_key;
$$ LANGUAGE sql;

-- Prune old attempt rows (run manually or via the optional cron job in §4).
CREATE OR REPLACE FUNCTION public.dash_prune_login_attempts()
RETURNS void AS $$
    DELETE FROM public.dash_login_attempts
    WHERE window_start < now() - INTERVAL '1 hour';
$$ LANGUAGE sql;

-- 2b. dash_save_field — atomic save/restore with optimistic-concurrency guard.
-- Handles both ordinary edits and "Restore" (a restore is just a forward save
-- of the target value). In ONE statement it:
--   • checks the caller's expected version against the live override version,
--   • upserts dash_override (version := expected + 1),
--   • appends a dash_edit_log row (old→new, author, version).
-- Returns jsonb: {ok, conflict, version, old_value}. On a version mismatch it
-- writes nothing and returns {ok:false, conflict:true, version:<live>} so the
-- UI can prompt a reload (409) instead of silently clobbering a concurrent edit.
CREATE OR REPLACE FUNCTION public.dash_save_field(
    p_field_id         uuid,
    p_new_value        text,
    p_expected_version int,
    p_editor           text
) RETURNS jsonb AS $$
DECLARE
    v_field       public.dash_field%ROWTYPE;
    v_live_ver    int;
    v_old_value   text;
    v_new_ver     int;
BEGIN
    SELECT * INTO v_field FROM public.dash_field WHERE id = p_field_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('ok', false, 'conflict', false, 'error', 'unknown_field');
    END IF;

    -- Live version is 0 when never overridden (value == baseline).
    SELECT version, current_value INTO v_live_ver, v_old_value
    FROM public.dash_override WHERE field_id = p_field_id;
    IF NOT FOUND THEN
        v_live_ver  := 0;
        v_old_value := v_field.baseline_value;
    END IF;

    IF v_live_ver <> p_expected_version THEN
        RETURN jsonb_build_object('ok', false, 'conflict', true, 'version', v_live_ver);
    END IF;

    v_new_ver := p_expected_version + 1;

    INSERT INTO public.dash_override (field_id, current_value, version, updated_by, updated_at)
    VALUES (p_field_id, p_new_value, v_new_ver, p_editor, now())
    ON CONFLICT (field_id)
        DO UPDATE SET current_value = EXCLUDED.current_value,
                      version       = EXCLUDED.version,
                      updated_by    = EXCLUDED.updated_by,
                      updated_at    = now();

    INSERT INTO public.dash_edit_log
        (field_id, field_path, file, group_key, old_value, new_value, version, edited_by)
    VALUES
        (p_field_id, v_field.field_path, v_field.file, v_field.group_key,
         v_old_value, p_new_value, v_new_ver, p_editor);

    RETURN jsonb_build_object('ok', true, 'conflict', false,
                              'version', v_new_ver, 'old_value', v_old_value);
END;
$$ LANGUAGE plpgsql;


-- 3. Row Level Security  (ENABLE + no policies = deny-all via PostgREST)
-- ────────────────────────────────────────────────────────────
-- Service-role key bypasses RLS, so server code still has full access.
ALTER TABLE public.dash_users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dash_baseline         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dash_field            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dash_override         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dash_edit_log         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dash_content_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dash_login_attempts   ENABLE ROW LEVEL SECURITY;


-- 4. Login-attempt pruning
-- ────────────────────────────────────────────────────────────
-- No scheduled job is created here (keeps this migration free of any extension
-- dependency, per the plan). The dash_login_attempts table is tiny (two users),
-- so call public.dash_prune_login_attempts() manually or from an external
-- scheduler if/when you want to trim old rows. If you prefer an automated prune
-- and pg_cron is already enabled on the project (001 uses it), you can add:
--   SELECT cron.schedule('dash-prune-login-attempts', '*/10 * * * *',
--                        $$ SELECT public.dash_prune_login_attempts() $$);
