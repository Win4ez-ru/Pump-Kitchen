import Foundation

enum RecipeStepLink {
    /// The backend sometimes returns a link to the original recipe instead of
    /// cooking steps. Detects such steps so the UI can show an
    /// "Open Original Recipe" button instead of raw URL text.
    static func url(from step: String) -> URL? {
        let trimmed = step.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstToken = trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) else {
            return nil
        }

        let lowercased = firstToken.lowercased()
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return URL(string: firstToken)
        }
        if lowercased.hasPrefix("www.") {
            return URL(string: "https://\(firstToken)")
        }
        return nil
    }
}
