import Foundation
import FirebaseFirestore

struct Conversation: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
}
