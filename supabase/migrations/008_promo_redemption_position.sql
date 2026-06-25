-- ════════════════════════════════════════════════════════════
-- 008: Promo redemption position (FIRST50 slot number)
-- ════════════════════════════════════════════════════════════
-- Persists each primary redemption's slot (1..max_redemptions) and
-- returns it as redemptionPosition in comp grant payloads.
-- ════════════════════════════════════════════════════════════

ALTER TABLE promo_redemptions
  ADD COLUMN IF NOT EXISTS slot_number INTEGER;

-- Backfill slot numbers from earliest redemption per install, ranked by code.
WITH primary_redemptions AS (
  SELECT DISTINCT ON (code_id, client_install_id)
    code_id,
    client_install_id,
    redeemed_at
  FROM promo_redemptions
  ORDER BY code_id, client_install_id, redeemed_at ASC
),
ranked AS (
  SELECT
    code_id,
    client_install_id,
    ROW_NUMBER() OVER (PARTITION BY code_id ORDER BY redeemed_at ASC) AS slot
  FROM primary_redemptions
)
UPDATE promo_redemptions r
SET slot_number = ranked.slot
FROM ranked
WHERE r.code_id = ranked.code_id
  AND r.client_install_id = ranked.client_install_id
  AND r.slot_number IS NULL;

-- Copy slot numbers onto cross-device rows for the same signed-in user.
UPDATE promo_redemptions r
SET slot_number = src.slot_number
FROM promo_redemptions src
WHERE r.slot_number IS NULL
  AND r.user_id IS NOT NULL
  AND src.user_id = r.user_id
  AND src.code_id = r.code_id
  AND src.slot_number IS NOT NULL
  AND src.redeemed_at = (
    SELECT MIN(redeemed_at)
    FROM promo_redemptions
    WHERE user_id = r.user_id
      AND code_id = r.code_id
      AND slot_number IS NOT NULL
  );

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
        'expiresAt', v_existing.grant_expires_at,
        'redemptionPosition', v_existing.slot_number
      )
    );
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
      ON CONFLICT (code_id, client_install_id) DO NOTHING;

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
        'expiresAt', v_redemption.grant_expires_at,
        'redemptionPosition', v_redemption.slot_number
      )
    );
  END IF;

  IF p_user_id IS NOT NULL THEN
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
  END IF;

  RETURN json_build_object('hasCompAccess', false);
END;
$$;

REVOKE ALL ON FUNCTION get_comp_access(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_comp_access(TEXT, UUID) TO service_role;
