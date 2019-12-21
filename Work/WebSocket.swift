import Foundation
import Combine

class WebSocket: NSObject {
    private let session = URLSession(configuration: .default)
    private var webSocketTask: URLSessionWebSocketTask?
    private var timer: Timer?

    let messageSubject = PassthroughSubject<Message, Error>()

    deinit {
        close()
    }

    func connect(to url: URL) {
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }

    func listen() {
        webSocketTask?.receive { [weak self] in
            switch $0 {
            case .success(let message):
                defer {
                    self?.listen()
                }
                switch message {
                case .data:
                    break
                case .string(let text):
                    print(text)
                    guard let data = text.data(using: .utf8),
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let type = jsonObject["type"] as? String else { return }
                    switch type {
                    case "message":
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        do {
                            let message = try decoder.decode(TextMessage.self, from: data)
                            self?.messageSubject.send(Message.text(message))
                        } catch {
                            print(error)
                        }
                    default:
                        break
                    }
                @unknown default:
                    break
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    func close() {
        timer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    func ping() {
        webSocketTask?.sendPing { error in
            self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                self.ping()
            }
        }
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("conneccted")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("disconneccted")
    }
}

enum Message: Hashable {
    case text(TextMessage)
}

struct TextMessage: Hashable, Decodable {
    let type: String
    let text: String
    let user: String
    let team: String
    let blocks: [MessageBlock]
    let channel: String
    let eventTs: String
    let files: [File]?
}

struct MessageBlock: Hashable, Decodable {
    let type: String
    let blockId: String
    let elements: [RichTextElement]
}

struct RichTextElement: Hashable, Decodable {
    let type: String
    let elements: [RichTextSectionElement]
}

struct RichTextSectionElement: Hashable, Decodable {
    let type: String

    let text: String?
    let style: RichTextStyle?

    let url: String?
}

struct RichTextStyle: Hashable, Decodable {
    let bold: Bool?
    let italic: Bool?
    let strike: Bool?
    let code: Bool?
}

struct File: Hashable, Decodable {
    let id: String
    let created: Int
    let timestamp: Int
    let name: String
    let title: String
    let mimetype: String
    let filetype: String
    let prettyType: String
    let user: String
    let editable: Bool
    let size: Int
    let mode: String
    let isExternal: Bool
    let externalType: String
    let isPublic: Bool
    let publicUrlShared: Bool
    let displayAsBot: Bool
    let username: String
    let urlPrivate: String
    let urlPrivateDownload: String
    let thumb64: String
    let thumb80: String
    let thumb360: String
    let thumb360W: Int
    let thumb360H: Int
    let thumb480: String
    let thumb480W: Int
    let thumb480H: Int
    let thumb160: String
    let thumb720: String
    let thumb720W: Int
    let thumb720H: Int
    let thumb800: String
    let thumb800W: Int
    let thumb800H: Int
    let thumb960: String
    let thumb960W: Int
    let thumb960H: Int
    let thumb1024: String
    let thumb1024W: Int
    let thumb1024H: Int
    let imageExifRotation: Int
    let originalW: Int
    let originalH: Int
    let thumbTiny: String
    let permalink: String
    let permalinkPublic: String
    let isStarred: Bool
    let hasRichPreview: Bool
}
