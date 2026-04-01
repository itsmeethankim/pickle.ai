import Foundation
import FirebaseFirestore

struct SwingAnalysis: Codable, Identifiable {
    @DocumentID var id: String?
    var createdAt: Date
    var videoUrl: String
    var videoDurationSeconds: Double
    var frameCount: Int
    var status: AnalysisStatus
    var overallScore: Int?
    var feedback: CoachingFeedback?
    var isPickleball: Bool
    var shotType: ShotType?
    var errorMessage: String?

    enum AnalysisStatus: String, Codable {
        case processing
        case completed
        case failed
    }
}
