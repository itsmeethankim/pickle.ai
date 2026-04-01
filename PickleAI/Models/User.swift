import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var createdAt: Date
    var analysisCount: Int
    var dailyAnalysisCount: Int
    var lastAnalysisDate: Date?
    var xp: Int = 0
    var currentStreak: Int = 0
    var level: Int = 1

    static func new(email: String, displayName: String) -> AppUser {
        AppUser(
            email: email,
            displayName: displayName,
            createdAt: Date(),
            analysisCount: 0,
            dailyAnalysisCount: 0,
            lastAnalysisDate: nil,
            xp: 0,
            currentStreak: 0,
            level: 1
        )
    }
}
