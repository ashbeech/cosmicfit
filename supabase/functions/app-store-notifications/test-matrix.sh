#!/usr/bin/env bash
# Post-deploy validation for app-store-notifications Edge Function.
# Run after: supabase functions deploy app-store-notifications
#
# Usage:
#   ./test-matrix.sh <function-url>
#   ./test-matrix.sh https://fkzxcxycyvzutbvgjzwu.supabase.co/functions/v1/app-store-notifications

set -euo pipefail

URL="${1:?Usage: $0 <function-url>}"
PASS=0
FAIL=0

check() {
  local label="$1" expected_status="$2" actual_status="$3"
  if [ "$actual_status" -eq "$expected_status" ]; then
    echo "  PASS  $label (HTTP $actual_status)"
    ((PASS++))
  else
    echo "  FAIL  $label — expected $expected_status, got $actual_status"
    ((FAIL++))
  fi
}

echo "=== App Store Notifications — Post-deploy test matrix ==="
echo "URL: $URL"
echo ""

# 1. Wrong method → 405
echo "--- HTTP method checks ---"
status=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$URL")
check "GET → 405" 405 "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$URL")
check "PUT → 405" 405 "$status"

# 2. Bad body → 400
echo ""
echo "--- Body validation ---"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d 'not json')
check "Invalid JSON → 400" 400 "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{}')
check "Empty body → 400" 400 "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{"signedPayload": 123}')
check "signedPayload not string → 400" 400 "$status"

# 3. Tampered / invalid JWS → 400
echo ""
echo "--- JWS validation ---"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{"signedPayload": "not.a.jws"}')
check "Garbage JWS → 400" 400 "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{"signedPayload": "eyJhbGciOiJFUzI1NiJ9.eyJ0ZXN0Ijp0cnVlfQ.AAAA"}')
check "JWS without x5c → 400" 400 "$status"

echo ""
echo "=== Automated results: $PASS passed, $FAIL failed ==="
echo ""
echo "=== Manual tests (require Apple sandbox) ==="
echo "These cannot be automated without real Apple-signed payloads:"
echo ""
echo "  [ ] ASC 'Send Test Notification' → 200, row in subscription_events"
echo "  [ ] Sandbox purchase (SUBSCRIBED) → 200, env=Sandbox"
echo "  [ ] Duplicate UUID re-POST → 200, still single row"
echo "  [ ] Sandbox renewal (DID_RENEW) → 200"
echo "  [ ] Sandbox cancel (EXPIRED) → 200"
echo "  [ ] Wrong bundleId in real signed payload → 400 (unlikely without custom cert)"
echo ""
echo "To verify DB rows:"
echo "  supabase db query 'SELECT notification_uuid, notification_type, environment, product_id, received_at FROM subscription_events ORDER BY received_at DESC LIMIT 10'"

[ "$FAIL" -eq 0 ] || exit 1
