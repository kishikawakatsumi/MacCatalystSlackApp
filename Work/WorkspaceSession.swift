import Foundation
import AuthenticationServices
import Combine
import KeychainAccess

class WorkspaceSession {
    @Published var accessToken: String?
    @Published var workspace: Workspace?

    private let host = "https://slack.com"
    private let client = APIClient()
    private let webSocket = WebSocket()

    private var cancellables = Set<AnyCancellable>()

    func authorize(clientID: String, clientSecret: String, code: String) -> AnyPublisher<AuthorizeResponse, APIError> {
        var components = URLComponents(string: host)!
        components.path = "/api/oauth.access"
        components.queryItems = [URLQueryItem(name: "client_id", value: clientID),
                                 URLQueryItem(name: "client_secret", value: clientSecret),
                                 URLQueryItem(name: "code", value: code),]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return client.request(request: request)
    }

    func bootstrap() {
        let session = self
        session.conversations()
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: {
                session.workspace?.channels = $0.channels
            })
            .store(in: &cancellables)

        session.connect()
            .compactMap { $0.url }
            .compactMap { URL(string: $0) }
            .sink(receiveCompletion: { _ in

            }, receiveValue: {
                session.listen(to: $0)
            })
            .store(in: &cancellables)
    }

    func connect() -> AnyPublisher<ConnectResponse, APIError> {
        var components = URLComponents(string: host)!
        components.path = "/api/rtm.connect"
        components.queryItems = [URLQueryItem(name: "token", value: accessToken)]

        var request = URLRequest(url: components.url!)
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return client.request(request: request)
    }

    func listen(to url: URL) {
        webSocket.connect(to: url)
        webSocket.messageSubject
            .sink(receiveCompletion: { _ in

            }) { [weak self] in
                self?.workspace?.appendMessage($0)
            }
            .store(in: &cancellables)
    }

    func conversations() -> AnyPublisher<ConversationsResponse, APIError> {
        var components = URLComponents(string: host)!
        components.path = "/api/users.conversations"
        
        components.queryItems = [URLQueryItem(name: "token", value: accessToken)]

        var request = URLRequest(url: components.url!)
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return client.request(request: request)
    }

    func userInfo(for userID: String) -> AnyPublisher<UserInfoResponse, APIError> {
        var components = URLComponents(string: host)!
        components.path = "/api/users.info"

        components.queryItems = [URLQueryItem(name: "token", value: accessToken),
                                 URLQueryItem(name: "user", value: userID),]

        var request = URLRequest(url: components.url!)
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return client.request(request: request)
    }
}

struct AuthorizeResponse: Hashable, Codable {
    var accessToken: String
    var scope: String
    var teamName: String
    var enterpriseId: String?
}

struct ConnectResponse: Hashable, Codable {
    var ok: Bool
    var `self`: `Self`
    var team: Team
    var url: String
}

struct `Self`: Hashable, Codable {
    var id: String
    var name: String
}

struct Team: Hashable, Codable {
    var domain: String
    var id: String
    var name: String
}

struct ConversationsResponse: Hashable, Codable {
    var ok: Bool
    var channels: [Channel]
}

struct Channel: Hashable, Codable {
    var id: String
    var name: String
}

struct UserInfoResponse: Hashable, Codable {
    var ok: Bool
    var user: User
}

struct User: Hashable, Codable {
    var id: String
    var teamId: String
    var name: String
    var deleted: Bool
    var color: String
    var realName: String
    var tz: String
    var tzLabel: String
    var tzOffset: Int
    var profile: UserProfile
    var isAdmin: Bool
    var isOwner: Bool
    var isRestricted: Bool
    var isUltraRestricted: Bool
    var isBot: Bool
    var isAppUser: Bool
}

struct UserProfile: Hashable, Codable {
    var avatarHash: String
    var statusText: String
    var statusEmoji: String
    var realName: String
    var displayName: String
    var realNameNormalized: String
    var displayNameNormalized: String
    var email: String
    var image24: String
    var image32: String
    var image48: String
    var image72: String
    var image192: String
    var image512: String
    var team: String
}
