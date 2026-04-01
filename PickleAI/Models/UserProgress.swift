import Foundation

struct UserProgress: Codable {
    var xp: Int = 0
    var level: Int = 1
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: Date?
    var unlockedAchievements: [String] = []
    var weeklyGoals: [WeeklyGoal] = []

    var levelName: String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        case 4: return "Pro"
        case 5...Int.max: return "Elite"
        default: return "Beginner"
        }
    }

    var xpForNextLevel: Int {
        return level * 500
    }

    var xpProgress: Double {
        let currentLevelXP = (level - 1) * 500
        let xpInCurrentLevel = xp - currentLevelXP
        let range = xpForNextLevel - currentLevelXP
        guard range > 0 else { return 1.0 }
        return min(Double(xpInCurrentLevel) / Double(range), 1.0)
    }
}

struct WeeklyGoal: Codable, Identifiable {
    var id: String = UUID().uuidString
    var type: GoalType
    var target: Int
    var current: Int = 0
    var weekOf: String

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var isCompleted: Bool { current >= target }

    enum GoalType: String, Codable, CaseIterable {
        case analyses = "Analyses"
        case practiceMinutes = "Practice Minutes"
        case chatSessions = "Chat Sessions"
        case streakDays = "Streak Days"

        var icon: String {
            switch self {
            case .analyses: return "video.fill"
            case .practiceMinutes: return "figure.run"
            case .chatSessions: return "bubble.left.fill"
            case .streakDays: return "flame.fill"
            }
        }
    }
}

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let requirement: String
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    static let all: [Achievement] = [
        Achievement(id: "first_analysis", name: "First Swing", description: "Complete your first video analysis", icon: "1.circle.fill", requirement: "1 analysis"),
        Achievement(id: "ten_analyses", name: "Dedicated Player", description: "Complete 10 video analyses", icon: "10.circle.fill", requirement: "10 analyses"),
        Achievement(id: "streak_7", name: "Week Warrior", description: "Maintain a 7-day streak", icon: "flame.fill", requirement: "7-day streak"),
        Achievement(id: "streak_30", name: "Monthly Master", description: "Maintain a 30-day streak", icon: "flame.circle.fill", requirement: "30-day streak"),
        Achievement(id: "score_80", name: "Top Form", description: "Score 80 or above on an analysis", icon: "star.fill", requirement: "Score 80+"),
        Achievement(id: "score_90", name: "Near Perfect", description: "Score 90 or above on an analysis", icon: "star.circle.fill", requirement: "Score 90+"),
        Achievement(id: "all_shots", name: "Complete Arsenal", description: "Analyze all shot types", icon: "trophy.fill", requirement: "All shot types"),
        Achievement(id: "first_plan", name: "Game Plan", description: "Generate your first practice plan", icon: "list.bullet.clipboard.fill", requirement: "1 practice plan"),
        Achievement(id: "chat_50", name: "Coach's Favorite", description: "Send 50 messages to the AI coach", icon: "bubble.left.and.text.bubble.right.fill", requirement: "50 chat messages"),
        Achievement(id: "xp_1000", name: "Rising Star", description: "Earn 1,000 XP", icon: "sparkles", requirement: "1,000 XP"),
        Achievement(id: "xp_5000", name: "Pickleball Pro", description: "Earn 5,000 XP", icon: "crown.fill", requirement: "5,000 XP"),
        Achievement(id: "goal_complete", name: "Goal Getter", description: "Complete a weekly goal", icon: "target", requirement: "1 weekly goal"),
    ]
}
