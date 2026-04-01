import Foundation

struct CoachingFeedback: Codable {
    var grip: CategoryFeedback
    var stance: CategoryFeedback
    var swingPath: CategoryFeedback
    var followThrough: CategoryFeedback
    var footwork: CategoryFeedback
    var generalTips: [String]

    var allCategories: [(name: String, feedback: CategoryFeedback)] {
        [
            ("Grip", grip),
            ("Stance", stance),
            ("Swing Path", swingPath),
            ("Follow Through", followThrough),
            ("Footwork", footwork)
        ]
    }
}

struct CategoryFeedback: Codable {
    var score: Int
    var tips: [String]
    var timestamp: Double
}
