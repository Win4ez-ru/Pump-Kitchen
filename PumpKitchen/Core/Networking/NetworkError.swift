import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badStatusCode(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL."
        case .invalidResponse:
            "Invalid server response."
        case .badStatusCode(let code):
            "Server returned status code \(code)."
        case .decodingFailed:
            "Unable to decode response."
        }
    }
}

