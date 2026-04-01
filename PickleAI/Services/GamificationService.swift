import Foundation
import FirebaseFirestore

class GamificationService {
    static let shared = GamificationService()
    private init() {}

    private let db = Firestore.firestore()

    // XP amounts
    static let xpAnalysis = 50
    static let xpChatMessage = 10
    static let xpDrillComplete = 25

    func awardXP(userId: String, amount: Int, reason: String) async {
        do {
            var progress = try await loadProgress(userId: userId)
            progress.xp += amount

            // Check level up
            while progress.xp >= progress.level * 500 {
                progress.level += 1
            }

            try await saveProgress(progress, userId: userId)
        } catch {
            // Non-critical, swallow errors silently
        }
    }

    func updateStreak(userId: String) async {
        do {
            var progress = try await loadProgress(userId: userId)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            if let lastActive = progress.lastActiveDate {
                let lastDay = calendar.startOfDay(for: lastActive)
                if calendar.isDate(lastDay, inSameDayAs: today) {
                    // Already active today, nothing to do
                    return
                }
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                if calendar.isDate(lastDay, inSameDayAs: yesterday) {
                    progress.currentStreak += 1
                } else {
                    progress.currentStreak = 1
                }
            } else {
                progress.currentStreak = 1
            }

            progress.lastActiveDate = Date()
            if progress.currentStreak > progress.longestStreak {
                progress.longestStreak = progress.currentStreak
            }

            // Streak bonus XP
            let streakBonus = progress.currentStreak * 5
            progress.xp += streakBonus
            while progress.xp >= progress.level * 500 {
                progress.level += 1
            }

            try await saveProgress(progress, userId: userId)
        } catch {
            // Non-critical
        }
    }

    @discardableResult
    func checkAchievements(
        userId: String,
        progress: UserProgress,
        analysisCount: Int,
        chatCount: Int,
        planCount: Int,
        highScore: Int,
        shotTypes: Set<String>
    ) async -> [Achievement] {
        var updated = progress
        var newlyUnlocked: [Achievement] = []

        let allShotTypes: Set<String> = ["serve", "return", "dink", "drive", "volley", "lob", "drop", "smash"]

        let conditions: [(String, Bool)] = [
            ("first_analysis", analysisCount >= 1),
            ("ten_analyses", analysisCount >= 10),
            ("streak_7", progress.currentStreak >= 7),
            ("streak_30", progress.currentStreak >= 30),
            ("score_80", highScore >= 80),
            ("score_90", highScore >= 90),
            ("all_shots", allShotTypes.isSubset(of: shotTypes)),
            ("first_plan", planCount >= 1),
            ("chat_50", chatCount >= 50),
            ("xp_1000", progress.xp >= 1000),
            ("xp_5000", progress.xp >= 5000),
            ("goal_complete", progress.weeklyGoals.contains { $0.isCompleted }),
        ]

        for (id, condition) in conditions {
            guard condition, !updated.unlockedAchievements.contains(id) else { continue }
            updated.unlockedAchievements.append(id)
            if let achievement = Achievement.all.first(where: { $0.id == id }) {
                newlyUnlocked.append(achievement)
            }
        }

        if !newlyUnlocked.isEmpty {
            do {
                try await saveProgress(updated, userId: userId)
            } catch {
                // Non-critical
            }
        }

        return newlyUnlocked
    }

    func loadProgress(userId: String) async throws -> UserProgress {
        let doc = try await db.collection("users").document(userId).collection("progress").document("current").getDocument()
        if doc.exists, let data = doc.data() {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return try decoder.decode(UserProgress.self, from: jsonData)
        }
        return UserProgress()
    }

    func saveProgress(_ progress: UserProgress, userId: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(progress)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await db.collection("users").document(userId).collection("progress").document("current").setData(dict)
    }
}
