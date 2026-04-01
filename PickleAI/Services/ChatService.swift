import Foundation
import FirebaseFunctions
import FirebaseFirestore

class ChatService {
    static let shared = ChatService()
    private init() {}

    private let functions = Functions.functions()
    private let db = Firestore.firestore()

    func sendMessage(conversationId: String, message: String, userId: String) async throws -> ChatMessage {
        let callable = functions.httpsCallable("coachChat")

        let payload: [String: Any] = [
            "conversationId": conversationId,
            "message": message,
            "userId": userId,
        ]

        let result = try await callable.call(payload)

        guard let data = result.data as? [String: Any] else {
            throw ChatError.invalidResponse
        }

        guard
            let role = data["role"] as? String,
            let content = data["content"] as? String
        else {
            throw ChatError.invalidResponse
        }

        let id = data["id"] as? String
        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else {
            createdAt = Date()
        }

        var msg = ChatMessage(role: role, content: content, createdAt: createdAt)
        msg.id = id
        return msg
    }

    func loadMessages(conversationId: String, userId: String) async throws -> [ChatMessage] {
        let snapshot = try await db
            .collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "createdAt")
            .getDocuments()

        return try snapshot.documents.map { try $0.data(as: ChatMessage.self) }
    }

    func createConversation(userId: String, title: String) async throws -> Conversation {
        let now = Date()
        var conversation = Conversation(title: title, createdAt: now, lastMessageAt: now)

        let collectionRef = db.collection("users").document(userId).collection("conversations")
        let docRef = try collectionRef.addDocument(from: conversation)
        conversation.id = docRef.documentID

        return conversation
    }

    func loadConversations(userId: String) async throws -> [Conversation] {
        let snapshot = try await db
            .collection("users").document(userId)
            .collection("conversations")
            .order(by: "lastMessageAt", descending: true)
            .limit(to: 20)
            .getDocuments()

        return try snapshot.documents.map { try $0.data(as: Conversation.self) }
    }
}

enum ChatError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the chat service."
        }
    }
}
