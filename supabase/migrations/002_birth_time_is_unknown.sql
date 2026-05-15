-- Add birth_time_is_unknown flag to profiles.
-- Existing rows default to false (indistinguishable from a real noon birth).
-- The existing handle_new_user() trigger INSERT omits this column,
-- so the DEFAULT covers new signups until the app starts passing it.

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS birth_time_is_unknown boolean NOT NULL DEFAULT false;
