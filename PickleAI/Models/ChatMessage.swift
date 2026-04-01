import Foundation
import FirebaseFirestore

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    var role: String
    var content: String
    var createdAt: Date
}
