import Foundation

/// Client HTTP léger (URLSession) pour le backend Vide-Grenier.
///
/// Gère le jeton d'authentification, le décodage JSON (dates ISO 8601 avec
/// millisecondes) et les requêtes GET/POST/multipart. Aucune dépendance externe.
actor APIClient {
    static let shared = APIClient()

    private var token: String?
    private let session = URLSession(configuration: .default)

    func setToken(_ token: String?) { self.token = token }

    // MARK: - Décodage

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withMillis = ISO8601DateFormatter()
        withMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = withMillis.date(from: raw) ?? plain.date(from: raw) { return date }
            throw AppError.decoding("date \(raw)")
        }
        return decoder
    }()

    // MARK: - Requêtes

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        var components = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        authorize(&request)
        return try await send(request)
    }

    @discardableResult
    func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        authorize(&request)
        return try await send(request)
    }

    /// Upload multipart d'une image JPEG déjà anonymisée.
    @discardableResult
    func uploadImage<T: Decodable>(_ path: String, imageData: Data) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        authorize(&request)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n"
            .data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        return try await send(request)
    }

    // MARK: - Privé

    private func authorize(_ request: inout URLRequest) {
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AppError.network("réponse") }
            guard (200..<300).contains(http.statusCode) else {
                if http.statusCode == 401 { throw AppError.notAuthenticated }
                if http.statusCode == 402 || http.statusCode == 409 { throw AppError.paymentFailed }
                throw AppError.network("HTTP \(http.statusCode)")
            }
            if T.self == EmptyResponse.self { return EmptyResponse() as! T }
            return try Self.decoder.decode(T.self, from: data)
        } catch let error as AppError {
            throw error
        } catch is DecodingError {
            throw AppError.decoding(request.url?.path ?? "")
        } catch {
            throw AppError.network(error.localizedDescription)
        }
    }
}

/// Réponse vide pour les endpoints qui ne renvoient pas de corps utile.
struct EmptyResponse: Decodable {}
