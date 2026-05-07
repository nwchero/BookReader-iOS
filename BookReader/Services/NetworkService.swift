import Foundation

final class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    func fetch(urlString: String, method: String = "GET", body: Data? = nil) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.encodingError
        }

        return html
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case serverError
    case encodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .serverError: return "服务器错误"
        case .encodingError: return "编码错误"
        }
    }
}
