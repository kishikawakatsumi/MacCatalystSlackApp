import Foundation

struct Workspace: Hashable {
    let name: String
    var channels = [Channel]()
    var messageStore = [String: [Message]]()

    mutating func appendMessage(_ message: Message) {
        switch message {
        case .text(let textMessage):
            if messageStore[textMessage.channel] == nil {
                messageStore[textMessage.channel] = [Message]()
            }
            messageStore[textMessage.channel]?.append(message)
        }
    }
}
