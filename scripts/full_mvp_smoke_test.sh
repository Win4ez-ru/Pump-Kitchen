#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${BASE_URL:-}"
if [[ -z "$BASE_URL" ]]; then
  echo "BASE_URL is required. Example: BASE_URL=\"https://your-backend.example.com\" $0" >&2
  exit 2
fi
BASE_URL="${BASE_URL%/}"
HEALTH_PATH="${HEALTH_PATH:-health}"
EMAIL="${EMAIL:-pumpkitchen.smoke.$(date +%s)@example.com}"
PASSWORD="${PASSWORD:-PumpKitchenSmoke123!}"
NAME="${NAME:-Pump Kitchen Smoke}"
GOAL="${GOAL:-maintenance}"
DIET="${DIET:-regular}"
ALLERGENS_JSON="${ALLERGENS_JSON:-[\"peanuts\"]}"
INGREDIENTS_JSON="${INGREDIENTS_JSON:-[\"chicken 250g\",\"rice 150g\",\"eggs 3\"]}"
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
  path="${path#/}"
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
echo "HEALTH_PATH=/$HEALTH_PATH"
echo "EMAIL=$EMAIL"
echo "GOAL=$GOAL, DIET=$DIET"
echo "ALLERGENS_JSON=$ALLERGENS_JSON"

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
STATUS=$(request GET "$HEALTH_PATH" "$TMP_DIR/health.json")
assert_status "$STATUS" 200 "Backend health" "$TMP_DIR/health.json"

step "Register user"
STATUS=$(request POST 'v1/auth/register' "$TMP_DIR/register.json" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"$NAME\"}")
assert_status "$STATUS" 200 "Registration" "$TMP_DIR/register.json"

step "Login"
STATUS=$(request POST 'v1/auth/login' "$TMP_DIR/login.json" \
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
STATUS=$(request PATCH 'v1/auth/me/profile' "$TMP_DIR/profile.json" \
  "${AUTH[@]}" -H 'Content-Type: application/json' \
  --data "$(python3 - "$GOAL" "$DIET" "$ALLERGENS_JSON" <<'PY'
import json, sys

allergens = json.loads(sys.argv[3])
if not isinstance(allergens, list) or not all(isinstance(item, str) for item in allergens):
    raise SystemExit("ALLERGENS_JSON must be a JSON string array")

print(json.dumps({
    "goal": sys.argv[1],
    "diet": sys.argv[2],
    "allergens": allergens,
}))
PY
)")
assert_status "$STATUS" 200 "Profile goal/diet update" "$TMP_DIR/profile.json"

step "Search recipes"
SEARCH_ARGS=()
while IFS= read -r arg; do
  SEARCH_ARGS+=("$arg")
done < <(python3 - "$INGREDIENTS_JSON" "$GOAL" "$DIET" <<'PY'
import json, sys

ingredients = json.loads(sys.argv[1])
if not isinstance(ingredients, list) or not ingredients:
    raise SystemExit("INGREDIENTS_JSON must be a non-empty JSON array")

args = ["--get"]
for ingredient in ingredients:
    if not isinstance(ingredient, str) or not ingredient.strip():
        raise SystemExit("Each ingredient must be a non-empty string")
    args.extend(["--data-urlencode", f"ingredients={ingredient}"])
args.extend(["--data-urlencode", f"goal={sys.argv[2]}"])
args.extend(["--data-urlencode", f"diet={sys.argv[3]}"])
for arg in args:
    print(arg)
PY
)
STATUS=$(request GET 'v1/recipes/search' "$TMP_DIR/recipes.json" "${AUTH[@]}" "${SEARCH_ARGS[@]}")
assert_status "$STATUS" 200 "Recipe search" "$TMP_DIR/recipes.json"

RECIPE_ID=$(python3 - "$TMP_DIR/recipes.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1]))
if isinstance(payload, dict):
    recipes = payload.get('recipes') or payload.get('results') or payload.get('items')
else:
    recipes = payload
assert isinstance(recipes, list), 'Response must be an array or {"recipes"|"results"|"items": [...]}'
assert 1 <= len(recipes) <= 3, 'Expected 1 to 3 recipe search results'

for index, recipe in enumerate(recipes, 1):
    assert isinstance(recipe, dict), f'Recipe search result {index} must be an object'
    assert recipe.get('title') not in (None, '', []), f'Recipe search result {index} missing title'
    assert recipe.get('id') not in (None, '', []) or recipe.get('spoonacular_id') not in (None, '', []), f'Recipe search result {index} missing id/spoonacular_id'

    ingredients = recipe.get('ingredients') or recipe.get('ingredients_full') or recipe.get('modified_ingredients')
    assert isinstance(ingredients, list) and ingredients, f'Recipe search result {index} missing full ingredients'

    steps = recipe.get('steps') or recipe.get('instructions') or recipe.get('modified_steps')
    assert isinstance(steps, list) and steps, f'Recipe search result {index} missing cooking steps'

    nutrition = recipe.get('nutrition') or recipe.get('modified_nutrition') or {}
    assert isinstance(nutrition, dict), f'Recipe search result {index} missing nutrition object'
    for field in ('calories', 'protein', 'carbs'):
        assert nutrition.get(field) not in (None, '', []), f'Recipe search result {index} missing nutrition.{field}'
    assert nutrition.get('fat') not in (None, '', []) or nutrition.get('fats') not in (None, '', []), (
        f'Recipe search result {index} missing nutrition.fat'
    )

print(recipes[0].get('id') or recipes[0].get('spoonacular_id'))
PY
) && pass "Recipe search results satisfy full recipe contract" || fail "Recipe search results violate full recipe contract"

step "Save favorite"
STATUS=$(request POST "v1/recipes/$RECIPE_ID/save" "$TMP_DIR/save.json" "${AUTH[@]}")
assert_status "$STATUS" 200 "Save recipe" "$TMP_DIR/save.json"

step "Fetch favorites"
STATUS=$(request GET 'v1/recipes/saved' "$TMP_DIR/saved.json" "${AUTH[@]}")
assert_status "$STATUS" 200 "Fetch saved recipes" "$TMP_DIR/saved.json"
FAVORITE_ID=$(python3 - "$TMP_DIR/saved.json" "$RECIPE_ID" <<'PY'
import json, sys
saved = json.load(open(sys.argv[1]))
expected = str(sys.argv[2])
for item in saved:
    if expected in {str(item.get('id')), str(item.get('spoonacular_id'))}:
        ingredients = item.get('ingredients') or item.get('ingredients_full') or item.get('modified_ingredients')
        steps = item.get('steps') or item.get('instructions') or item.get('modified_steps')
        nutrition = item.get('nutrition') or item.get('modified_nutrition') or {}
        assert isinstance(ingredients, list) and ingredients, 'Saved recipe missing full ingredients'
        assert isinstance(steps, list) and steps, 'Saved recipe missing cooking steps'
        assert isinstance(nutrition, dict) and nutrition.get('calories') not in (None, '', []), 'Saved recipe missing nutrition'
        print(item.get('id') or item.get('spoonacular_id'))
        break
else:
    raise AssertionError('Saved recipe is absent from favorites')
PY
) && pass "Saved recipe appears in favorites" || fail "Saved recipe is absent from favorites"

step "Delete favorite"
STATUS=$(request DELETE "v1/recipes/$FAVORITE_ID/save" "$TMP_DIR/delete.json" "${AUTH[@]}")
assert_status "$STATUS" 200 "Delete saved recipe" "$TMP_DIR/delete.json"

step "Negative auth check"
STATUS=$(request GET 'v1/recipes/saved' "$TMP_DIR/unauthorized.json")
if [[ "$STATUS" == "401" || "$STATUS" == "403" ]]; then
  pass "Protected endpoint rejects anonymous request ($STATUS)"
else
  fail "Protected endpoint should return 401/403, received $STATUS"
fi

printf '\n========================================\n'
printf 'Pump Kitchen MVP smoke test: %s passed, %s failed\n' "$PASS" "$FAIL"
printf '========================================\n'
[[ "$FAIL" == "0" ]]
