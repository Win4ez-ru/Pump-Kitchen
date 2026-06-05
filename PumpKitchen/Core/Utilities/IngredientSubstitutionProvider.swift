import Foundation

enum IngredientSubstitutionProvider {
    static func substitutions(for ingredientName: String) -> [String] {
        let name = ingredientName.lowercased()

        let rules: [(keywords: [String], substitutions: [String])] = [
            (["tomato paste", "томат"], ["tomato sauce reduced in a pan", "canned tomatoes blended", "roasted red pepper puree"]),
            (["chicken", "кур"], ["turkey breast", "lean pork", "firm tofu"]),
            (["rice", "рис"], ["quinoa", "bulgur", "buckwheat"]),
            (["egg", "яй"], ["Greek yogurt binder", "silken tofu", "chia gel"]),
            (["milk", "мол"], ["unsweetened oat milk", "soy milk", "water plus yogurt"]),
            (["butter", "слив"], ["olive oil", "ghee", "Greek yogurt for creamy sauces"]),
            (["soy sauce", "соев"], ["tamari", "coconut aminos", "salt plus lemon juice"]),
            (["cream", "сливки"], ["Greek yogurt", "coconut milk", "blended cottage cheese"]),
            (["cheese", "сыр"], ["cottage cheese", "nutritional yeast", "Greek yogurt plus salt"])
        ]

        for rule in rules where rule.keywords.contains(where: name.contains) {
            return rule.substitutions
        }

        return [
            "similar ingredient with matching texture",
            "same ingredient category with lower calories",
            "omit and increase seasoning if it is only for flavor"
        ]
    }
}
