#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${BASE_URL:-https://fraternal-euphemism-snowflake.ngrok-free.dev}"
EMAIL="${EMAIL:-pumpkitchen.smoke.$(date +%s)@example.com}"
PASSWORD="${PASSWORD:-PumpKitchenSmoke123!}"
NAME="${NAME:-Pump Kitchen Smoke}"
GOAL="${GOAL:-maintenance}"
DIET="${DIET:-regular}"
INGREDIENTS_JSON="${INGREDIENTS_JSON:-[\"chicken 250g\",\"rice\",\"eggs\"]}"
DERIVED_DATA="${DERIVED_DATA:-.DerivedDataSmokeTest}"
SKIP_BUILD="${SKIP_BUILD:-0}"
KEEP_ARTIFACTS="${KEEP_ARTIFACTS:-0}"

PASS=0
FAIL=0
TMP_DIR="$(mktemp -d)"
TOKEN=""

cleanup() {
  if [[ "$KEEP_ARTIFACTS" != "1" ]]; then
    rm -rf "$TMP_DIR" "$DERIVED_DATA"
  else
    echo "Artifacts: $TMP_DIR and $DERIVED_DATA"
  fi
}
trap cleanup EXIT

pass() { PASS=$((PASS + 1)); printf '✅ %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '❌ %s\n' "$1" >&2; return 1; }
step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$1"; }

request() {
  local method="$1" path="$2" output="$3"; shift 3
  local status
  status=$(curl --max-time 150 --silent --show-error \
    -H 'ngrok-skip-browser-warning: true' \
    -X "$method" "$BASE_URL/$path" \
    -o "$output" -w '%{http_code}' "$@")
  printf '%s' "$status"
}

assert_status() {
  local actual="$1" expected="$2" label="$3" body="$4"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label ($actual)"
  else
    cat "$body" >&2 || true
    fail "$label: expected $expected, received $actual"
  fi
}

step "Configuration"
echo "BASE_URL=$BASE_URL"
echo "EMAIL=$EMAIL"
echo "GOAL=$GOAL, DIET=$DIET"

if [[ "$SKIP_BUILD" != "1" ]]; then
  step "Build iOS MVP"
  if xcodebuild -project 'Pump Kitchen.xcodeproj' -scheme 'Pump Kitchen' \
      -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO build \
      >"$TMP_DIR/xcodebuild.log" 2>&1; then
    pass "iOS Simulator build succeeded"
  else
    tail -80 "$TMP_DIR/xcodebuild.log" >&2
    fail "iOS Simulator build failed"
  fi
fi

step "Backend health"
STATUS=$(request GET '' "$TMP_DIR/health.json")
assert_status "$STATUS" 200 "Backend health" "$TMP_DIR/health.json"

step "Register user"
STATUS=$(request POST 'auth/register' "$TMP_DIR/register.json" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"$NAME\"}")
assert_status "$STATUS" 200 "Registration" "$TMP_DIR/register.json"

step "Login"
STATUS=$(request POST 'auth/login' "$TMP_DIR/login.json" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "username=$EMAIL" --data-urlencode "password=$PASSWORD")
assert_status "$STATUS" 200 "Login" "$TMP_DIR/login.json"
TOKEN=$(python3 - "$TMP_DIR/login.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1])).get('access_token', ''))
PY
)
[[ -n "$TOKEN" ]] && pass "Bearer token received" || fail "Bearer token is missing"
AUTH=(-H "Authorization: Bearer $TOKEN")

step "Update profile"
STATUS=$(request PATCH 'auth/me/profile' "$TMP_DIR/profile.json" \
  "${AUTH[@]}" -H 'Content-Type: application/json' \
  --data "{\"goal\":\"$GOAL\",\"diet\":\"$DIET\"}")
assert_status "$STATUS" 200 "Profile goal/diet update" "$TMP_DIR/profile.json"

step "Generate recipes"
STATUS=$(request POST 'recipes/generate' "$TMP_DIR/recipes.json" \
  "${AUTH[@]}" -H 'Content-Type: application/json' \
  --data "{\"ingredients\":$INGREDIENTS_JSON}")
assert_status "$STATUS" 200 "Recipe generation" "$TMP_DIR/recipes.json"

RECIPE_ID=$(python3 - "$TMP_DIR/recipes.json" <<'PY'
import json, sys
recipes = json.load(open(sys.argv[1]))
if isinstance(recipes, dict): recipes = recipes.get('recipes', [])
assert isinstance(recipes, list), 'Response must be an array or {"recipes": [...]}'
assert 3 <= len(recipes) <= 5, f'Expected 3–5 recipes, received {len(recipes)}'
required = ['id', 'title', 'ingredients_full', 'steps', 'nutrition']
for index, recipe in enumerate(recipes, 1):
    missing = [key for key in required if key not in recipe or recipe[key] in (None, '', [])]
    assert not missing, f'Recipe {index} missing fields: {missing}'
    nutrition = recipe['nutrition']
    assert isinstance(nutrition, dict), f'Recipe {index} nutrition must be object'
    for key in ['calories', 'protein', 'fat', 'carbs']:
        assert key in nutrition, f'Recipe {index} nutrition missing {key}'
print(recipes[0]['id'])
PY
) && pass "Generated recipes satisfy MVP contract" || fail "Generated recipes violate MVP contract"

step "Save favorite"
STATUS=$(request POST "recipes/$RECIPE_ID/save" "$TMP_DIR/save.json" "${AUTH[@]}")
assert_status "$STATUS" 200 "Save recipe" "$TMP_DIR/save.json"

step "Fetch favorites"
STATUS=$(request GET 'recipes/saved' "$TMP_DIR/saved.json" "${AUTH[@]}")
assert_status "$STATUS" 200 "Fetch saved recipes" "$TMP_DIR/saved.json"
python3 - "$TMP_DIR/saved.json" "$RECIPE_ID" <<'PY'
import json, sys
saved = json.load(open(sys.argv[1]))
expected = str(sys.argv[2])
assert any(str(item.get('id')) == expected for item in saved), 'Saved recipe is absent from favorites'
PY
pass "Saved recipe appears in favorites"

step "Delete favorite"
STATUS=$(request DELETE "recipes/$RECIPE_ID/save" "$TMP_DIR/delete.json" "${AUTH[@]}")
assert_status "$STATUS" 200 "Delete saved recipe" "$TMP_DIR/delete.json"

step "Negative auth check"
STATUS=$(request GET 'recipes/saved' "$TMP_DIR/unauthorized.json")
if [[ "$STATUS" == "401" || "$STATUS" == "403" ]]; then
  pass "Protected endpoint rejects anonymous request ($STATUS)"
else
  fail "Protected endpoint should return 401/403, received $STATUS"
fi

printf '\n========================================\n'
printf 'Pump Kitchen MVP smoke test: %s passed, %s failed\n' "$PASS" "$FAIL"
printf '========================================\n'
[[ "$FAIL" == "0" ]]
