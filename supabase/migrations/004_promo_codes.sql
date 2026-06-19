-- ════════════════════════════════════════════════════════════
-- 004: Promo / comp code redemption
-- ════════════════════════════════════════════════════════════
-- Server-validated promo codes that grant complimentary full
-- access without an App Store subscription. Scoped to
-- client_install_id (device) with optional user_id for
-- cross-device restore when signed in.
--
-- SAFE TO RUN ON PRODUCTION:
--   All CREATE IF NOT EXISTS / DO NOTHING — fully idempotent.
-- ════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────
-- 1. promo_codes — inventory of available codes
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS promo_codes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code             TEXT NOT NULL UNIQUE,
  kind             TEXT NOT NULL DEFAULT 'comp'
    CHECK (kind IN ('comp')),
  grant_days       INTEGER,                         -- NULL = permanent
  max_redemptions  INTEGER NOT NULL DEFAULT 1,
  redemption_count INTEGER NOT NULL DEFAULT 0,
  expires_at       TIMESTAMPTZ,                     -- NULL = never expires
  is_active        BOOLEAN NOT NULL DEFAULT true,
  is_dev_only      BOOLEAN NOT NULL DEFAULT false,
  note             TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_promo_codes_code
  ON promo_codes(code);

-- ────────────────────────────────────────────────────────────
-- 2. promo_redemptions — audit log
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS promo_redemptions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id           UUID NOT NULL REFERENCES promo_codes(id),
  client_install_id TEXT NOT NULL,
  user_id           UUID REFERENCES auth.users(id),
  grant_expires_at  TIMESTAMPTZ,
  redeemed_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(code_id, client_install_id)
);

CREATE INDEX IF NOT EXISTS idx_promo_redemptions_user
  ON promo_redemptions(user_id)
  WHERE user_id IS NOT NULL;

-- ────────────────────────────────────────────────────────────
-- 3. RLS — service-role only
-- ────────────────────────────────────────────────────────────

ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_redemptions ENABLE ROW LEVEL SECURITY;

GRANT ALL ON promo_codes TO service_role;
GRANT ALL ON promo_redemptions TO service_role;

-- ────────────────────────────────────────────────────────────
-- 4. redeem_promo_code RPC
-- ────────────────────────────────────────────────────────────
-- Validates and atomically redeems a code. Returns JSON with
-- grant payload on success, or error on failure.
-- Idempotent: re-redeeming from the same install or user
-- returns the existing grant without error.

CREATE OR REPLACE FUNCTION redeem_promo_code(
  p_code              TEXT,
  p_client_install_id TEXT,
  p_user_id           UUID DEFAULT NULL,
  p_is_dev_build      BOOLEAN DEFAULT false
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_promo        RECORD;
  v_existing     RECORD;
  v_grant_expires TIMESTAMPTZ;
BEGIN
  SELECT * INTO v_promo
  FROM promo_codes
  WHERE code = UPPER(TRIM(p_code));

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', 'INVALID_CODE');
  END IF;

  IF NOT v_promo.is_active THEN
    RETURN json_build_object('ok', false, 'error', 'INVALID_CODE');
  END IF;

  IF v_promo.is_dev_only AND NOT p_is_dev_build THEN
    RETURN json_build_object('ok', false, 'error', 'INVALID_CODE');
  END IF;

  IF v_promo.expires_at IS NOT NULL AND now() >= v_promo.expires_at THEN
    RETURN json_build_object('ok', false, 'error', 'CODE_EXPIRED');
  END IF;

  -- Idempotent: same install already redeemed this code
  SELECT * INTO v_existing
  FROM promo_redemptions
  WHERE code_id = v_promo.id AND client_install_id = p_client_install_id;

  IF FOUND THEN
    RETURN json_build_object(
      'ok', true,
      'alreadyRedeemed', true,
      'grant', json_build_object(
        'code', v_promo.code,
        'grantedAt', v_existing.redeemed_at,
        'expiresAt', v_existing.grant_expires_at
      )
    );
  END IF;

  -- Idempotent: same user on a different install
  IF p_user_id IS NOT NULL THEN
    SELECT * INTO v_existing
    FROM promo_redemptions
    WHERE code_id = v_promo.id AND user_id = p_user_id;

    IF FOUND THEN
      -- Record this install too so future lookups are local
      v_grant_expires := v_existing.grant_expires_at;
      INSERT INTO promo_redemptions (code_id, client_install_id, user_id, grant_expires_at)
      VALUES (v_promo.id, p_client_install_id, p_user_id, v_grant_expires)
      ON CONFLICT (code_id, client_install_id) DO NOTHING;

      RETURN json_build_object(
        'ok', true,
        'alreadyRedeemed', true,
        'grant', json_build_object(
          'code', v_promo.code,
          'grantedAt', v_existing.redeemed_at,
          'expiresAt', v_grant_expires
        )
      );
    END IF;
  END IF;

  IF v_promo.redemption_count >= v_promo.max_redemptions THEN
    RETURN json_build_object('ok', false, 'error', 'INVALID_CODE');
  END IF;

  -- Compute grant expiry
  IF v_promo.grant_days IS NOT NULL THEN
    v_grant_expires := now() + (v_promo.grant_days || ' days')::INTERVAL;
  ELSE
    v_grant_expires := NULL;
  END IF;

  UPDATE promo_codes
  SET redemption_count = redemption_count + 1
  WHERE id = v_promo.id;

  INSERT INTO promo_redemptions (code_id, client_install_id, user_id, grant_expires_at)
  VALUES (v_promo.id, p_client_install_id, p_user_id, v_grant_expires);

  RETURN json_build_object(
    'ok', true,
    'alreadyRedeemed', false,
    'grant', json_build_object(
      'code', v_promo.code,
      'grantedAt', now(),
      'expiresAt', v_grant_expires
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION redeem_promo_code(TEXT, TEXT, UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION redeem_promo_code(TEXT, TEXT, UUID, BOOLEAN) TO service_role;

-- ────────────────────────────────────────────────────────────
-- 5. get_comp_access RPC
-- ────────────────────────────────────────────────────────────
-- Returns the active comp grant for an install or user,
-- used for restoring access after reinstall / new device.

CREATE OR REPLACE FUNCTION get_comp_access(
  p_client_install_id TEXT,
  p_user_id           UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_redemption RECORD;
  v_promo      RECORD;
BEGIN
  -- Try by install ID first
  SELECT r.*, c.code
  INTO v_redemption
  FROM promo_redemptions r
  JOIN promo_codes c ON c.id = r.code_id
  WHERE r.client_install_id = p_client_install_id
    AND c.is_active = true
    AND (r.grant_expires_at IS NULL OR r.grant_expires_at > now())
  ORDER BY r.redeemed_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN json_build_object(
      'hasCompAccess', true,
      'grant', json_build_object(
        'code', v_redemption.code,
        'grantedAt', v_redemption.redeemed_at,
        'expiresAt', v_redemption.grant_expires_at
      )
    );
  END IF;

  -- Fall back to user ID lookup for cross-device restore
  IF p_user_id IS NOT NULL THEN
    SELECT r.*, c.code
    INTO v_redemption
    FROM promo_redemptions r
    JOIN promo_codes c ON c.id = r.code_id
    WHERE r.user_id = p_user_id
      AND c.is_active = true
      AND (r.grant_expires_at IS NULL OR r.grant_expires_at > now())
    ORDER BY r.redeemed_at DESC
    LIMIT 1;

    IF FOUND THEN
      RETURN json_build_object(
        'hasCompAccess', true,
        'grant', json_build_object(
          'code', v_redemption.code,
          'grantedAt', v_redemption.redeemed_at,
          'expiresAt', v_redemption.grant_expires_at
        )
      );
    END IF;
  END IF;

  RETURN json_build_object('hasCompAccess', false);
END;
$$;

REVOKE ALL ON FUNCTION get_comp_access(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_comp_access(TEXT, UUID) TO service_role;

-- ────────────────────────────────────────────────────────────
-- 6. Seed BETATESTER code
-- ────────────────────────────────────────────────────────────

INSERT INTO promo_codes (code, kind, grant_days, max_redemptions, is_dev_only, note)
VALUES ('BETATESTER', 'comp', NULL, 100, false, 'Beta testers — permanent full access')
ON CONFLICT (code) DO NOTHING;
