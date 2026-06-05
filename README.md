# Pump Kitchen

SwiftUI iOS app for generating recipes from available ingredients with nutrition targeting. The iOS app is frontend-only: AI provider secrets live on the backend.

## Stack

- Swift
- SwiftUI
- MVVM
- async/await
- URLSession
- Codable
- SwiftData
- iOS 18+
- Xcode 26

## Architecture

The app is split by feature and shared core layers. Views own presentation, ViewModels own state and user actions, and services/repositories are injected through protocols from `AppContainer`.

```text
App
- AppEntry
- Navigation

Core
- Networking
- Models
- Storage
- DesignSystem
- Utilities

Features
- Home
- Onboarding
- RecipeDetails
- Favorites
- History
- Settings
```

## Current MVP

- First-run onboarding for goal, protein target, and servings.
- Ingredient chips input with comma-separated paste support.
- Fitness goal, protein target, and servings controls.
- Backend-ready recipe generation service with mock fallback.
- Recipe details with nutrition, ingredients, instructions, tags, and favorite action.
- Favorites and history stored locally via SwiftData.
- Swipe-to-delete in Favorites and History.
- Backend configuration in Settings.
- Premium minimal SwiftUI design system.

## Backend

See `BACKEND_CONTRACT.md` for the API contract expected by the iOS app.

## Next Steps

1. Add app icon and launch visuals.
2. Add request retry and richer backend error states.
3. Add UI tests for main generation flow.
4. Add app config for dev/stage/prod backend URLs.
5. Add localization after MVP copy stabilizes.
