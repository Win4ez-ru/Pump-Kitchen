import Foundation

/// The backend only understands English ingredient names, and its raw names
/// (for example "Chicken breast raw") are not display-ready in Russian.
/// This translator bridges both directions with the local lexicon:
/// user input -> English search terms, backend names -> Russian display names.
enum IngredientTranslator {
    // MARK: - Search (RU -> EN)

    /// Converts free-form user input like "курочка 250г" into a backend-ready
    /// search item like "chicken 250g". Latin input is passed through
    /// unchanged because the backend autocorrects English on its own.
    static func searchTerm(for rawInput: String) -> String {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        let (name, quantity) = splitQuantity(from: trimmed)
        guard containsCyrillic(name) else { return trimmed }

        let translatedName = translateToEnglish(name) ?? name
        guard let quantity else { return translatedName }
        return "\(translatedName) \(quantity)"
    }

    // MARK: - Display (EN -> RU)

    /// Returns a display-ready ingredient name for the current locale.
    /// Non-Russian locales and names that are already Cyrillic pass through.
    static func displayName(for backendName: String, locale: Locale) -> String {
        guard locale.language.languageCode?.identifier == "ru" else { return backendName }
        let trimmed = backendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !containsCyrillic(trimmed) else { return backendName }

        let normalized = normalize(trimmed)
        guard !normalized.isEmpty else { return backendName }

        for (key, entry) in englishKeysByLength where matches(key, in: normalized) {
            return entry.russian
        }
        return backendName
    }

    // MARK: - English lookup

    private static func translateToEnglish(_ name: String) -> String? {
        let normalized = normalize(name)
        guard !normalized.isEmpty else { return nil }

        if let exact = russianIndex[normalized] {
            return exact.english
        }

        // Whole-phrase fuzzy pass catches typos like "куринная грудка".
        if let fuzzy = bestFuzzyMatch(for: normalized, among: russianKeys) {
            return russianIndex[fuzzy]?.english
        }

        // Longest known synonym inside the phrase: "свежая куриная грудка".
        for key in russianKeysByLength where matches(key, in: normalized) {
            return russianIndex[key]?.english
        }

        // Word-by-word fuzzy pass as the last resort.
        for word in normalized.split(separator: " ").map(String.init) where word.count >= 3 {
            if let fuzzy = bestFuzzyMatch(for: word, among: russianKeys) {
                return russianIndex[fuzzy]?.english
            }
        }
        return nil
    }

    // MARK: - Quantity handling

    private static let unitMap: [String: String] = [
        "г": "g", "гр": "g", "грамм": "g", "грамма": "g", "граммов": "g",
        "кг": "kg", "килограмм": "kg",
        "мл": "ml", "л": "l", "литр": "l", "литра": "l",
        "шт": "", "штук": "", "штуки": "",
        "g": "g", "kg": "kg", "ml": "ml", "l": "l",
        "ст.л": "tbsp", "ст.л.": "tbsp", "ч.л": "tsp", "ч.л.": "tsp",
        "tbsp": "tbsp", "tsp": "tsp", "cup": "cup", "cups": "cup", "pcs": ""
    ]

    /// Splits "курица 250г" / "курица 250 г" / "яйца 3" into the name part
    /// and a backend-ready quantity like "250g" or "3".
    private static func splitQuantity(from input: String) -> (name: String, quantity: String?) {
        var nameTokens: [String] = []
        var quantity: String?

        let tokens = input.split(whereSeparator: \.isWhitespace).map(String.init)
        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            if quantity == nil, let parsed = parseQuantityToken(token) {
                if parsed.unit.isEmpty,
                   index + 1 < tokens.count,
                   let mappedUnit = unitMap[tokens[index + 1].lowercased()] {
                    quantity = parsed.number + mappedUnit
                    index += 2
                    continue
                }
                quantity = parsed.number + parsed.unit
            } else {
                nameTokens.append(token)
            }
            index += 1
        }

        return (nameTokens.joined(separator: " "), quantity)
    }

    private static func parseQuantityToken(_ token: String) -> (number: String, unit: String)? {
        let lowercased = token.lowercased()
        let numberPart = lowercased.prefix { $0.isNumber || $0 == "." || $0 == "," }
        guard !numberPart.isEmpty else { return nil }

        let suffix = String(lowercased.dropFirst(numberPart.count))
        let number = numberPart.replacingOccurrences(of: ",", with: ".")
        if suffix.isEmpty {
            return (number, "")
        }
        guard let mappedUnit = unitMap[suffix] else { return nil }
        return (number, mappedUnit)
    }

    // MARK: - Matching helpers

    private static func bestFuzzyMatch(for value: String, among keys: [String]) -> String? {
        let threshold = value.count > 5 ? 2 : 1
        var best: (key: String, distance: Int)?

        for key in keys {
            guard abs(key.count - value.count) <= threshold else { continue }
            let distance = levenshteinDistance(value, key)
            if distance <= threshold, distance < (best?.distance ?? .max) {
                best = (key, distance)
                if distance == 0 { break }
            }
        }
        return best?.key
    }

    static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsCharacters = Array(lhs)
        let rhsCharacters = Array(rhs)
        guard !lhsCharacters.isEmpty else { return rhsCharacters.count }
        guard !rhsCharacters.isEmpty else { return lhsCharacters.count }

        var previousRow = Array(0...rhsCharacters.count)
        var currentRow = [Int](repeating: 0, count: rhsCharacters.count + 1)

        for (lhsIndex, lhsCharacter) in lhsCharacters.enumerated() {
            currentRow[0] = lhsIndex + 1
            for (rhsIndex, rhsCharacter) in rhsCharacters.enumerated() {
                let substitutionCost = lhsCharacter == rhsCharacter ? 0 : 1
                currentRow[rhsIndex + 1] = min(
                    previousRow[rhsIndex + 1] + 1,
                    currentRow[rhsIndex] + 1,
                    previousRow[rhsIndex] + substitutionCost
                )
            }
            swap(&previousRow, &currentRow)
        }
        return previousRow[rhsCharacters.count]
    }

    private static func matches(_ key: String, in phrase: String) -> Bool {
        " \(phrase) ".contains(" \(key) ")
    }

    private static func containsCyrillic(_ value: String) -> Bool {
        value.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
    }

    private static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .map { $0.isLetter || $0.isNumber ? $0 : " " }
            .reduce(into: "") { result, character in
                if character == " ", result.hasSuffix(" ") { return }
                result.append(character)
            }
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Indexes

    private static let russianIndex: [String: IngredientLexiconEntry] = {
        var index: [String: IngredientLexiconEntry] = [:]
        for entry in IngredientLexicon.entries {
            for synonym in entry.ru where index[synonym] == nil {
                index[synonym] = entry
            }
        }
        return index
    }()

    private static let russianKeys: [String] = Array(russianIndex.keys)

    private static let russianKeysByLength: [String] = russianKeys.sorted {
        $0.count > $1.count
    }

    private static let englishKeysByLength: [(String, IngredientLexiconEntry)] = {
        var pairs: [(String, IngredientLexiconEntry)] = []
        var seen = Set<String>()
        for entry in IngredientLexicon.entries {
            for synonym in [entry.english] + entry.en where seen.insert(synonym).inserted {
                pairs.append((synonym, entry))
            }
        }
        return pairs.sorted { $0.0.count > $1.0.count }
    }()
}
