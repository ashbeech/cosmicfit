-- ════════════════════════════════════════════════════════════
-- 005: Revoke comp access for a device install
-- ════════════════════════════════════════════════════════════
-- Removes the promo_redemptions row for client_install_id so
-- the device loses comp access until a code is redeemed again.

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
  v_redemption RECORD;
BEGIN
  SELECT r.*, c.code
  INTO v_redemption
  FROM promo_redemptions r
  JOIN promo_codes c ON c.id = r.code_id
  WHERE r.client_install_id = p_client_install_id
  ORDER BY r.redeemed_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object('ok', true, 'revoked', false);
  END IF;

  DELETE FROM promo_redemptions
  WHERE id = v_redemption.id;

  UPDATE promo_codes
  SET redemption_count = GREATEST(0, redemption_count - 1)
  WHERE id = v_redemption.code_id;

  RETURN json_build_object(
    'ok', true,
    'revoked', true,
    'code', v_redemption.code
  );
END;
$$;

REVOKE ALL ON FUNCTION revoke_comp_access(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION revoke_comp_access(TEXT, UUID) TO service_role;
