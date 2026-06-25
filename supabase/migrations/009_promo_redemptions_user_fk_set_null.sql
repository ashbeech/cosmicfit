-- ════════════════════════════════════════════════════════════
-- 009: Alter promo_redemptions user_id FK to ON DELETE SET NULL
-- ════════════════════════════════════════════════════════════
-- Previously the FK had no ON DELETE action, meaning
-- auth.admin.deleteUser() would fail with a FK violation for
-- any user who had redeemed a promo code.
--
-- SET NULL preserves the audit row (code, client_install_id,
-- timestamps, slot_number) while allowing the auth user to be
-- removed. The edge function also nullifies proactively, but
-- this constraint acts as a safety net.
--
-- SAFE TO RUN ON PRODUCTION: idempotent (drops IF EXISTS).
-- ════════════════════════════════════════════════════════════

-- Drop the existing unnamed FK constraint on user_id.
-- Postgres auto-names it based on table/column; find and drop it.
DO $$
DECLARE
  fk_name TEXT;
BEGIN
  SELECT tc.constraint_name INTO fk_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  WHERE tc.table_name = 'promo_redemptions'
    AND tc.table_schema = 'public'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'user_id';

  IF fk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.promo_redemptions DROP CONSTRAINT %I', fk_name);
  END IF;
END;
$$;

-- Re-add with ON DELETE SET NULL
ALTER TABLE public.promo_redemptions
  ADD CONSTRAINT promo_redemptions_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
