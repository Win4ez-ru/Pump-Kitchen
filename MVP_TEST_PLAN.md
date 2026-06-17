# Pump Kitchen — Full MVP Test Plan

## Automated smoke test

Run from the project root:

```bash
./scripts/full_mvp_smoke_test.sh
```

For a new backend URL:

```bash
BASE_URL="https://new-backend.example.com" ./scripts/full_mvp_smoke_test.sh
```

Skip the Xcode build when testing only the API:

```bash
SKIP_BUILD=1 BASE_URL="https://new-backend.example.com" ./scripts/full_mvp_smoke_test.sh
```

The script verifies:

- iOS Simulator build;
- backend health;
- registration and login;
- Bearer token;
- profile goal/diet update;
- generation of exactly 3–5 valid recipes;
- required recipe fields and nutrition;
- save, fetch and delete favorite;
- unauthorized access rejection.

## Manual iOS acceptance test

### 1. Authentication

- Launch a clean installation.
- Confirm Login/Register screen appears.
- Register a new user.
- Confirm the app opens after successful registration.
- Log out from Profile and log in again.
- Confirm an incorrect password displays a readable error.

### 2. Onboarding and profile

- Complete onboarding with goal and diet.
- Open Profile and change goal and diet.
- Tap **Save Profile**.
- Confirm the message says the profile synced with backend.
- Restart the app and confirm values remain selected.

### 3. Recipe generation

- Add `chicken 250g`, `rice`, and `eggs`.
- Tap **Generate Recipes**.
- Confirm loading state is visible.
- Confirm 3–5 recipe cards appear.
- Every card must contain title, image/fallback, description, time, difficulty and approximate nutrition.
- Confirm empty ingredients cannot start generation.
- Confirm a backend error produces a readable error state.

### 4. Recipe details

- Open every generated recipe.
- Confirm image/fallback, title, description, time and difficulty.
- Confirm ingredient amounts and numbered cooking steps.
- Confirm calories, protein, fats and carbs.
- Confirm tips/lifehacks appear when returned by backend.
- Confirm ingredient substitution sheet opens.
- Enter a fixed ingredient amount and confirm scaling preview changes quantities.

### 5. Favorites

- Add a backend recipe to favorites.
- Confirm the heart state changes immediately.
- Open Favorites and confirm the recipe appears.
- Open the saved recipe.
- Remove it using swipe action and confirm it disappears.
- Restart the app and confirm backend favorites remain synchronized.

### 6. Mock mode

- Enable **Use Mock Backend** in Profile.
- Generate recipes without a backend connection.
- Add and remove a mock favorite.
- Disable mock mode and confirm backend authentication is required.

## MVP release criteria

- Automated smoke script passes with zero failures.
- Debug and Release builds succeed.
- No crashes during the full manual flow.
- Recipe generation returns 3–5 recipes in under 30 seconds.
- Authentication token never appears in logs or UI.
- All user-facing errors are readable and actionable.
