/**
 * Promo code user isolation — SQL-level tests.
 *
 * Requires a running local Supabase instance (`supabase start`).
 * All test data is cleaned up in afterEach.
 *
 * Run:  cd supabase/functions && deno task test
 */

import {
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";

function svc(): SupabaseClient {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
}

const TEST_INSTALL_A = "test-install-aaa";
const TEST_INSTALL_B = "test-install-bbb";

// Deterministic UUIDs for test users (not real auth users, just for promo_redemptions FK-free rows).
const USER_A = "00000000-0000-0000-0000-00000000000a";
const USER_B = "00000000-0000-0000-0000-00000000000b";

async function cleanup() {
  const client = svc();
  await client.from("promo_redemptions").delete().in("client_install_id", [
    TEST_INSTALL_A,
    TEST_INSTALL_B,
  ]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

Deno.test({
  name: "get_comp_access: User B on same device does NOT see User A's grant",
  async fn() {
    await cleanup();
    const client = svc();

    // User A redeems
    await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });

    // User B checks on same device
    const { data } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_B,
    });

    assertEquals(data.hasCompAccess, false, "User B must NOT see User A's grant");
    await cleanup();
  },
});

Deno.test({
  name: "get_comp_access: User A still sees own grant on same device",
  async fn() {
    await cleanup();
    const client = svc();

    await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });

    const { data } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });

    assertEquals(data.hasCompAccess, true, "User A should see own grant");
    await cleanup();
  },
});

Deno.test({
  name: "get_comp_access: guest redemption visible only when p_user_id IS NULL",
  async fn() {
    await cleanup();
    const client = svc();

    // Guest redeems
    await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: null,
    });

    // Guest check
    const { data: guestResult } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: null,
    });
    assertEquals(guestResult.hasCompAccess, true, "Guest should see guest grant");

    // Authenticated check — must NOT see the guest row
    const { data: authResult } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(authResult.hasCompAccess, false, "Auth user must NOT see guest grant");

    await cleanup();
  },
});

Deno.test({
  name: "redeem_promo_code: User B can redeem on same device after User A (separate slot)",
  async fn() {
    await cleanup();
    const client = svc();

    const { data: rA } = await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(rA.ok, true);

    const { data: rB } = await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_B,
    });
    assertEquals(rB.ok, true, "User B should be able to redeem on same device");

    // Both should have different slot numbers (unless at quota limit)
    if (!rA.alreadyRedeemed && !rB.alreadyRedeemed) {
      assertNotEquals(
        rA.grant.redemptionPosition,
        rB.grant.redemptionPosition,
        "Different users should get different slot numbers",
      );
    }

    await cleanup();
  },
});

Deno.test({
  name: "redeem_promo_code: same user + same device is idempotent",
  async fn() {
    await cleanup();
    const client = svc();

    const { data: r1 } = await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(r1.ok, true);

    const { data: r2 } = await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(r2.ok, true);
    assertEquals(r2.alreadyRedeemed, true);
    assertEquals(r2.grant.redemptionPosition, r1.grant.redemptionPosition);

    await cleanup();
  },
});

Deno.test({
  name: "redeem_promo_code: guest redeem then sign-in claims the guest row",
  async fn() {
    await cleanup();
    const client = svc();

    // Guest redeems
    const { data: guestRedeem } = await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: null,
    });
    assertEquals(guestRedeem.ok, true);
    const guestSlot = guestRedeem.grant.redemptionPosition;

    // Same device, now signed in — should claim guest row
    const { data: authRedeem } = await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(authRedeem.ok, true);
    assertEquals(authRedeem.alreadyRedeemed, true, "Should be idempotent via guest claim");
    assertEquals(authRedeem.grant.redemptionPosition, guestSlot, "Should preserve original slot number");

    // Auth check should now work
    const { data: check } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(check.hasCompAccess, true, "Claimed grant should be visible to auth user");

    await cleanup();
  },
});

Deno.test({
  name: "revoke_comp_access: deletes only the caller's row, not another user's",
  async fn() {
    await cleanup();
    const client = svc();

    // Both users redeem
    await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    await client.rpc("redeem_promo_code", {
      p_code: "FIRST50",
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_B,
    });

    // User A revokes
    const { data: revoke } = await client.rpc("revoke_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(revoke.ok, true);
    assertEquals(revoke.revoked, true);

    // User A should have no access
    const { data: checkA } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_A,
    });
    assertEquals(checkA.hasCompAccess, false, "User A should lose access after revoke");

    // User B should still have access
    const { data: checkB } = await client.rpc("get_comp_access", {
      p_client_install_id: TEST_INSTALL_A,
      p_user_id: USER_B,
    });
    assertEquals(checkB.hasCompAccess, true, "User B's grant should be unaffected");

    await cleanup();
  },
});
