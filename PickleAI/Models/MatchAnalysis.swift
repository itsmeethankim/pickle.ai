import Foundation
import FirebaseFirestore

struct MatchSegment: Codable, Identifiable {
    var id: UUID = UUID()
    var startTime: Double
    var endTime: Double
    var shotType: String
    var score: Int
    var feedback: CoachingFeedback?
    var isKeyMoment: Bool

    enum CodingKeys: String, CodingKey {
        case startTime, endTime, shotType, score, feedback, isKeyMoment
    }
}

extension MatchSegment {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
        shotType = try container.decode(String.self, forKey: .shotType)
        score = try container.decode(Int.self, forKey: .score)
        feedback = try container.decodeIfPresent(CoachingFeedback.self, forKey: .feedback)
        isKeyMoment = try container.decode(Bool.self, forKey: .isKeyMoment)
    }
}

struct MatchReport: Codable {
    var overallScore: Int
    var strengths: [String]
    var weaknesses: [String]
    var keyMoments: [String]
    var recommendations: [String]
}

struct MatchAnalysis: Codable, Identifiable {
    @DocumentID var id: String?
    var createdAt: Date
    var videoUrl: String
    var videoDurationSeconds: Double
    var frameCount: Int
    var segments: [MatchSegment]
    var matchReport: MatchReport
}
