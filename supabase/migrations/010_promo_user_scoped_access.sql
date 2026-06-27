-- ════════════════════════════════════════════════════════════
-- 010: User-scoped promo access (cross-user leak fix)
-- ════════════════════════════════════════════════════════════
-- The device-first lookup pattern in get_comp_access and the
-- UNIQUE(code_id, client_install_id) constraint allowed
-- User B to inherit User A's comp access on the same device
-- (Keychain install ID survives reinstall).
--
-- This migration:
--   1. Replaces the device-only unique constraint with partial
--      indexes scoped by user_id (authenticated vs guest).
--   2. Rewrites get_comp_access with strict auth-split lookups
--      so authenticated users never see another user's rows.
--   3. Rewrites redeem_promo_code with user-scoped idempotency
--      and a guest→user claim step for sign-up handoff.
--   4. Rewrites revoke_comp_access to delete only the caller's
--      row on the device.
--
-- SAFE TO RUN ON PRODUCTION: idempotent (DROP IF EXISTS, OR
-- REPLACE). Parameter signatures are unchanged.
-- ════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────
-- 1. Replace UNIQUE(code_id, client_install_id) with partial
--    unique indexes scoped by user_id.
-- ────────────────────────────────────────────────────────────

ALTER TABLE promo_redemptions
  DROP CONSTRAINT IF EXISTS promo_redemptions_code_id_client_install_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS promo_redemptions_code_install_user
  ON promo_redemptions (code_id, client_install_id, user_id)
  WHERE user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS promo_redemptions_code_install_guest
  ON promo_redemptions (code_id, client_install_id)
  WHERE user_id IS NULL;

-- ────────────────────────────────────────────────────────────
-- 2. get_comp_access — strict auth-split lookups
-- ────────────────────────────────────────────────────────────

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
BEGIN
  IF p_user_id IS NOT NULL THEN
    -- Authenticated path 1: user-scoped lookup (cross-device restore)
    SELECT r.*, c.code
    INTO v_redemption
    FROM promo_redemptions r
    JOIN promo_codes c ON c.id = r.code_id
    WHERE r.user_id = p_user_id
      AND c.is_active = true
      AND (r.grant_expires_at IS NULL OR r.grant_expires_at > now())
    ORDER BY r.redeemed_at ASC
    LIMIT 1;

    IF FOUND THEN
      RETURN json_build_object(
        'hasCompAccess', true,
        'grant', json_build_object(
          'code', v_redemption.code,
          'grantedAt', v_redemption.redeemed_at,
          'expiresAt', v_redemption.grant_expires_at,
          'redemptionPosition', v_redemption.slot_number
        )
      );
    END IF;

    -- Authenticated path 2: same user on this device (strict equality)
    SELECT r.*, c.code
    INTO v_redemption
    FROM promo_redemptions r
    JOIN promo_codes c ON c.id = r.code_id
    WHERE r.client_install_id = p_client_install_id
      AND r.user_id = p_user_id
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
          'expiresAt', v_redemption.grant_expires_at,
          'redemptionPosition', v_redemption.slot_number
        )
      );
    END IF;
  ELSE
    -- Guest path: device rows with NULL user_id only
    SELECT r.*, c.code
    INTO v_redemption
    FROM promo_redemptions r
    JOIN promo_codes c ON c.id = r.code_id
    WHERE r.client_install_id = p_client_install_id
      AND r.user_id IS NULL
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
          'expiresAt', v_redemption.grant_expires_at,
          'redemptionPosition', v_redemption.slot_number
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
-- 3. redeem_promo_code — user-scoped idempotency + guest claim
-- ────────────────────────────────────────────────────────────

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
  v_lookup_code   TEXT;
  v_promo         RECORD;
  v_existing      RECORD;
  v_grant_expires TIMESTAMPTZ;
  v_slot_number   INTEGER;
BEGIN
  v_lookup_code := UPPER(TRIM(p_code));
  IF v_lookup_code = 'BETATESTER' THEN
    v_lookup_code := 'FIRST50';
  END IF;

  SELECT * INTO v_promo
  FROM promo_codes
  WHERE code = v_lookup_code;

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

  -- Idempotent: same install + same user already redeemed this code
  SELECT * INTO v_existing
  FROM promo_redemptions
  WHERE code_id = v_promo.id
    AND client_install_id = p_client_install_id
    AND (
      (p_user_id IS NOT NULL AND user_id = p_user_id)
      OR (p_user_id IS NULL AND user_id IS NULL)
    );

  IF FOUND THEN
    RETURN json_build_object(
      'ok', true,
      'alreadyRedeemed', true,
      'grant', json_build_object(
        'code', v_promo.code,
        'grantedAt', v_existing.redeemed_at,
        'expiresAt', v_existing.grant_expires_at,
        'redemptionPosition', v_existing.slot_number
      )
    );
  END IF;

  -- Guest → sign-up handoff: claim existing guest row on this device
  IF p_user_id IS NOT NULL THEN
    UPDATE promo_redemptions
    SET user_id = p_user_id
    WHERE code_id = v_promo.id
      AND client_install_id = p_client_install_id
      AND user_id IS NULL
    RETURNING * INTO v_existing;

    IF FOUND THEN
      RETURN json_build_object(
        'ok', true,
        'alreadyRedeemed', true,
        'grant', json_build_object(
          'code', v_promo.code,
          'grantedAt', v_existing.redeemed_at,
          'expiresAt', v_existing.grant_expires_at,
          'redemptionPosition', v_existing.slot_number
        )
      );
    END IF;
  END IF;

  -- Idempotent: same user on a different install
  IF p_user_id IS NOT NULL THEN
    SELECT * INTO v_existing
    FROM promo_redemptions
    WHERE code_id = v_promo.id AND user_id = p_user_id
    ORDER BY redeemed_at ASC
    LIMIT 1;

    IF FOUND THEN
      v_grant_expires := v_existing.grant_expires_at;
      INSERT INTO promo_redemptions (
        code_id, client_install_id, user_id, grant_expires_at, slot_number
      )
      VALUES (
        v_promo.id, p_client_install_id, p_user_id, v_grant_expires, v_existing.slot_number
      )
      ON CONFLICT (code_id, client_install_id, user_id)
        WHERE user_id IS NOT NULL
        DO NOTHING;

      RETURN json_build_object(
        'ok', true,
        'alreadyRedeemed', true,
        'grant', json_build_object(
          'code', v_promo.code,
          'grantedAt', v_existing.redeemed_at,
          'expiresAt', v_grant_expires,
          'redemptionPosition', v_existing.slot_number
        )
      );
    END IF;
  END IF;

  IF v_promo.redemption_count >= v_promo.max_redemptions THEN
    RETURN json_build_object('ok', false, 'error', 'INVALID_CODE');
  END IF;

  IF v_promo.grant_days IS NOT NULL THEN
    v_grant_expires := now() + (v_promo.grant_days || ' days')::INTERVAL;
  ELSE
    v_grant_expires := NULL;
  END IF;

  UPDATE promo_codes
  SET redemption_count = redemption_count + 1
  WHERE id = v_promo.id
  RETURNING redemption_count INTO v_slot_number;

  INSERT INTO promo_redemptions (
    code_id, client_install_id, user_id, grant_expires_at, slot_number
  )
  VALUES (
    v_promo.id, p_client_install_id, p_user_id, v_grant_expires, v_slot_number
  );

  RETURN json_build_object(
    'ok', true,
    'alreadyRedeemed', false,
    'grant', json_build_object(
      'code', v_promo.code,
      'grantedAt', now(),
      'expiresAt', v_grant_expires,
      'redemptionPosition', v_slot_number
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION redeem_promo_code(TEXT, TEXT, UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION redeem_promo_code(TEXT, TEXT, UUID, BOOLEAN) TO service_role;

-- ────────────────────────────────────────────────────────────
-- 4. revoke_comp_access — delete only the caller's row
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION revoke_comp_access(
  p_client_install_id TEXT,
  p_user_id           UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_deleted RECORD;
BEGIN
  DELETE FROM promo_redemptions r
  USING promo_codes c
  WHERE r.code_id = c.id
    AND r.client_install_id = p_client_install_id
    AND (
      (p_user_id IS NOT NULL AND r.user_id = p_user_id)
      OR (p_user_id IS NULL AND r.user_id IS NULL)
    )
  RETURNING r.id, r.code_id, c.code INTO v_deleted;

  IF NOT FOUND THEN
    RETURN json_build_object('ok', true, 'revoked', false);
  END IF;

  UPDATE promo_codes
  SET redemption_count = GREATEST(0, redemption_count - 1)
  WHERE id = v_deleted.code_id;

  RETURN json_build_object(
    'ok', true,
    'revoked', true,
    'code', v_deleted.code
  );
END;
$$;

REVOKE ALL ON FUNCTION revoke_comp_access(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION revoke_comp_access(TEXT, UUID) TO service_role;
