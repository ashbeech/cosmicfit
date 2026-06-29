-- ════════════════════════════════════════════════════════════
-- 011: Unique promo slot numbers (race condition + revoke fix)
-- ════════════════════════════════════════════════════════════
-- Root cause: slot_number was derived from redemption_count,
-- which gets decremented on revocation. After a revoke + new
-- redeem the new user could receive a slot_number already held
-- by someone else.  The initial SELECT also lacked FOR UPDATE,
-- leaving a TOCTOU window for concurrent redemptions.
--
-- This migration:
--   1. Adds a monotonic next_slot_number to promo_codes (never
--      decremented, even on revoke).
--   2. Renumbers existing slots so each distinct user has a
--      unique slot ordered by first-redemption time.
--   3. Initialises next_slot_number from the new max slot.
--   4. Syncs redemption_count with actual distinct-user count.
--   5. Rewrites redeem_promo_code with FOR UPDATE serialisation
--      and next_slot_number-based assignment.
--   6. Rewrites revoke_comp_access to only decrement
--      redemption_count (not next_slot_number).
--
-- SAFE TO RUN ON PRODUCTION: idempotent (ADD IF NOT EXISTS,
-- OR REPLACE).
-- ════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────
-- 1. Add monotonic slot counter
-- ────────────────────────────────────────────────────────────

ALTER TABLE promo_codes
  ADD COLUMN IF NOT EXISTS next_slot_number INTEGER NOT NULL DEFAULT 1;

-- ────────────────────────────────────────────────────────────
-- 2. Renumber existing slots: one unique number per distinct
--    user entity, ordered by earliest redemption.
--    Cross-device copies of the same user share a slot.
-- ────────────────────────────────────────────────────────────

WITH user_first_redeemed AS (
  SELECT
    code_id,
    COALESCE(user_id::text, client_install_id) AS identity_key,
    MIN(redeemed_at) AS first_redeemed
  FROM promo_redemptions
  GROUP BY code_id, COALESCE(user_id::text, client_install_id)
),
user_new_slots AS (
  SELECT
    code_id,
    identity_key,
    ROW_NUMBER() OVER (
      PARTITION BY code_id
      ORDER BY first_redeemed ASC
    ) AS new_slot
  FROM user_first_redeemed
)
UPDATE promo_redemptions pr
SET slot_number = uns.new_slot::integer
FROM user_new_slots uns
WHERE pr.code_id = uns.code_id
  AND COALESCE(pr.user_id::text, pr.client_install_id) = uns.identity_key;

-- ────────────────────────────────────────────────────────────
-- 3. Initialise next_slot_number from max assigned slot
-- ────────────────────────────────────────────────────────────

UPDATE promo_codes pc
SET next_slot_number = COALESCE(
  (SELECT MAX(slot_number) + 1
   FROM promo_redemptions
   WHERE code_id = pc.id),
  1
);

-- ────────────────────────────────────────────────────────────
-- 4. Sync redemption_count with actual distinct-user count
-- ────────────────────────────────────────────────────────────

UPDATE promo_codes pc
SET redemption_count = COALESCE(
  (SELECT COUNT(DISTINCT COALESCE(user_id::text, client_install_id))
   FROM promo_redemptions
   WHERE code_id = pc.id),
  0
);

-- ────────────────────────────────────────────────────────────
-- 5. redeem_promo_code — FOR UPDATE + next_slot_number
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

  -- Serialise all concurrent redemptions for this code
  SELECT * INTO v_promo
  FROM promo_codes
  WHERE code = v_lookup_code
  FOR UPDATE;

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

  -- Assign from the monotonic counter — never reuses revoked slots
  v_slot_number := v_promo.next_slot_number;

  UPDATE promo_codes
  SET redemption_count = redemption_count + 1,
      next_slot_number = next_slot_number + 1
  WHERE id = v_promo.id;

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
-- 6. revoke_comp_access — only decrements redemption_count;
--    next_slot_number is intentionally untouched so revoked
--    slot numbers are never reassigned.
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
