import Foundation

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

