import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var currentConversation: Conversation? = nil
    @Published var messageText = ""

    func loadConversations(userId: String) async {
        do {
            conversations = try await ChatService.shared.loadConversations(userId: userId)
        } catch {
            print("Failed to load conversations: \(error.localizedDescription)")
        }
    }

    func loadMessages(conversationId: String, userId: String) async {
        do {
            messages = try await ChatService.shared.loadMessages(conversationId: conversationId, userId: userId)
        } catch {
            print("Failed to load messages: \(error.localizedDescription)")
        }
    }

    func sendMessage(userId: String) async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let conversation = currentConversation, let conversationId = conversation.id else { return }

        let userMessage = ChatMessage(role: "user", content: text, createdAt: Date())
        messages.append(userMessage)
        messageText = ""
        isLoading = true

        do {
            let reply = try await ChatService.shared.sendMessage(
                conversationId: conversationId,
                message: text,
                userId: userId
            )
            messages.append(reply)
        } catch {
            print("Failed to send message: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func createNewConversation(userId: String) async {
        do {
            let conversation = try await ChatService.shared.createConversation(userId: userId, title: "New Conversation")
            currentConversation = conversation
            conversations.insert(conversation, at: 0)
            messages = []
        } catch {
            print("Failed to create conversation: \(error.localizedDescription)")
        }
    }
}
