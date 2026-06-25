-- ════════════════════════════════════════════════════════════
-- 007: Rename BETATESTER promo code to FIRST50
-- ════════════════════════════════════════════════════════════
-- Renames the seeded comp code for existing deployments and
-- keeps BETATESTER as a legacy alias at redemption time.
-- ════════════════════════════════════════════════════════════

UPDATE promo_codes
SET code = 'FIRST50',
    max_redemptions = 50,
    note = 'First 50 — permanent full access'
WHERE code = 'BETATESTER';

INSERT INTO promo_codes (code, kind, grant_days, max_redemptions, is_dev_only, note)
VALUES ('FIRST50', 'comp', NULL, 50, false, 'First 50 — permanent full access')
ON CONFLICT (code) DO NOTHING;

UPDATE promo_codes
SET max_redemptions = 50
WHERE code = 'FIRST50';

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
