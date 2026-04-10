import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound(code: String?, message: String?)
    case badRequest(code: String?, message: String?)
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .notFound(_, let message):
            return message ?? "Resource not found"
        case .badRequest(_, let message):
            return message ?? "Bad request"
        case .unauthorized:
            return "Unauthorized"
        case .serverError(let statusCode, let message):
            return message ?? "Server error (\(statusCode))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return error.localizedDescription
        }
    }

    var isNotFound: Bool {
        if case .notFound = self { return true }
        return false
    }
}

// MARK: - API Error Response

private struct APIErrorResponse: Decodable {
    let error: APIError?
    let message: String?

    struct APIError: Decodable {
        let code: String?
        let message: String?
    }

    var errorMessage: String? {
        error?.message ?? message
    }

    var errorCode: String? {
        error?.code
    }
}

// MARK: - Network Service

final class NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private var baseURL: String { ConfigManager.shared.liveSearchAPIURL }

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Send a request and decode the response
    func send<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30
    ) async throws -> T {
        let request = try buildRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: headers,
            timeout: timeout
        )

        let (data, _) = try await execute(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Send a request without expecting a decoded response (for void responses)
    func send(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30
    ) async throws {
        let request = try buildRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: headers,
            timeout: timeout
        )

        _ = try await execute(request)
    }

    // MARK: - Request Building

    private func buildRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String],
        timeout: TimeInterval
    ) throws -> URLRequest {
        let urlString = endpoint.hasPrefix("http") ? endpoint : "\(baseURL)\(endpoint)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout

        // Set headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    // MARK: - Request Execution

    private func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validateResponse(httpResponse, data: data)

        return (data, httpResponse)
    }

    // MARK: - Response Validation

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return // Success

        case 400:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw NetworkError.badRequest(
                code: errorResponse?.errorCode,
                message: errorResponse?.errorMessage
            )

        case 401:
            throw NetworkError.unauthorized

        case 404:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw NetworkError.notFound(
                code: errorResponse?.errorCode,
                message: errorResponse?.errorMessage
            )

        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw NetworkError.serverError(
                statusCode: response.statusCode,
                message: errorResponse?.errorMessage
            )
        }
    }
}
