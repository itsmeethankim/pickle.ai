import Foundation
import FirebaseFunctions
import FirebaseFirestore

class MatchAnalysisService {
    static let shared = MatchAnalysisService()
    private init() {}

    private let functions = Functions.functions()
    private let db = Firestore.firestore()

    func analyzeMatch(
        frames: [String],
        userId: String,
        videoUrl: String,
        videoDuration: Double
    ) async throws -> MatchAnalysis {
        let callable = functions.httpsCallable("analyzeMatch")

        let payload: [String: Any] = [
            "frames": frames,
            "userId": userId,
            "videoDuration": videoDuration,
        ]

        let result = try await callable.call(payload)

        guard let data = result.data as? [String: Any] else {
            throw MatchAnalysisError.invalidResponse
        }

        let jsonData = try JSONSerialization.data(withJSONObject: data)

        struct PartialResponse: Decodable {
            let segments: [MatchSegment]
            let matchReport: MatchReport
        }

        let partial = try JSONDecoder().decode(PartialResponse.self, from: jsonData)

        var analysis = MatchAnalysis(
            createdAt: Date(),
            videoUrl: videoUrl,
            videoDurationSeconds: videoDuration,
            frameCount: frames.count,
            segments: partial.segments,
            matchReport: partial.matchReport
        )

        let collectionRef = db.collection("users").document(userId).collection("matchAnalyses")
        let docRef = try collectionRef.addDocument(from: analysis)
        analysis.id = docRef.documentID

        return analysis
    }
}

enum MatchAnalysisError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the match analysis service."
        }
    }
}
