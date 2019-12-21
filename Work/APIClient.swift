import Foundation
import Combine

class APIClient {
    private let session = URLSession(configuration: .default)

    func request<Response>(request: URLRequest) -> AnyPublisher<Response, APIError> where Response: Decodable {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return session.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
                    throw APIError.response(statusCode: response.statusCode, data: data)
                }
                return data
        }
        .mapError { (error) -> APIError in
            .network(underlyingError: error)
        }
        .decode(type: Response.self, decoder: decoder)
        .mapError { (error) -> APIError in
            .decoding(underlyingError: error)
        }
        .eraseToAnyPublisher()
    }
}

enum APIError: Error {
    case network(underlyingError: Error)
    case decoding(underlyingError: Error)
    case response(statusCode: Int, data: Data)
}
