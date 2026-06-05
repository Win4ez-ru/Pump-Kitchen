import Foundation

protocol APIClient {
    func send<Request: Encodable, Response: Decodable>(
        _ request: Request,
        to endpoint: APIEndpoint
    ) async throws -> Response
}

