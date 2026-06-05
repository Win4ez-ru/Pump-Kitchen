# Pump Kitchen Backend Contract

The iOS app never stores AI provider secrets. Backend owns OpenAI or any other AI provider keys.

## Base URL

In the iOS MVP, the backend base URL is configured in `Profile`.

Example:

```text
https://api.pumpkitchen.app
```

The app calls:

```http
POST /v1/recipes/generate
```

## Generate Recipes Request

```json
{
  "ingredients": ["chicken breast 200g", "rice", "eggs 2"],
  "fitnessGoal": "muscleGain",
  "profile": {
    "heightCentimeters": 180,
    "weightKilograms": 82,
    "activityLevel": "moderate",
    "goal": "muscleGain"
  }
}
```

### Fields

- `ingredients`: required array of strings. Items may include user-provided amounts, for example `chicken 200g`.
- `fitnessGoal`: string enum: `muscleGain`, `fatLoss`, `maintenance`.
- `profile.heightCentimeters`: number.
- `profile.weightKilograms`: number.
- `profile.activityLevel`: string enum: `low`, `moderate`, `high`.
- `profile.goal`: string enum: `muscleGain`, `fatLoss`, `maintenance`.

## Backend Behavior

- If the user gives an amount for one ingredient, use it as an anchor and scale the rest of the recipe around it.
- The backend calculates approximate calories and macros from profile + goal.
- The iOS app does not ask the user for protein grams or servings in the main flow.
- Portion guidance should be returned inside each recipe instruction/ingredient set.

## Success Response

```json
{
  "recipes": [
    {
      "id": "A2A44A30-1B73-4A1A-92C6-4C67C90E67F8",
      "title": "High Protein Rice Bowl",
      "cookingTimeMinutes": 25,
      "ingredients": [
        {
          "name": "Chicken breast",
          "amount": "200 g"
        },
        {
          "name": "Cooked rice",
          "amount": "180 g"
        }
      ],
      "instructions": [
        "Cook the rice until tender.",
        "Sear the chicken until golden.",
        "Combine and season to taste."
      ],
      "nutrition": {
        "calories": 620,
        "protein": 48,
        "fats": 18,
        "carbs": 66
      },
      "tags": ["High Protein", "Balanced"]
    }
  ]
}
```

### Response Notes

- `id` is optional for iOS; if missing, the app generates a local UUID.
- Nutrition values are approximate for the returned portion.
- Return 1 to 3 recipes for MVP.
- Return JSON only, no markdown.

## Error Response

Use a non-2xx status code and this body shape:

```json
{
  "message": "Unable to generate recipes for the provided ingredients."
}
```

## Future Ingredient Substitution Endpoint

The current iOS MVP has local substitute suggestions. Backend can later replace them with this endpoint:

```http
POST /v1/ingredients/substitutions
```

```json
{
  "ingredient": "tomato paste",
  "recipeTitle": "Chicken Rice Bowl",
  "fitnessGoal": "fatLoss",
  "profile": {
    "heightCentimeters": 180,
    "weightKilograms": 82,
    "activityLevel": "moderate",
    "goal": "fatLoss"
  }
}
```

Expected response:

```json
{
  "substitutions": [
    "tomato sauce reduced in a pan",
    "blended canned tomatoes",
    "roasted red pepper puree"
  ]
}
```

## Backend Responsibilities

- Store AI provider API keys securely on the server.
- Validate request fields.
- Calculate nutrition targets from profile and goal.
- Use fixed ingredient amounts as anchors when provided by the user.
- Return JSON in the exact response shape above.
- Add rate limiting before public release.
- Add auth later when the app gets user accounts.

