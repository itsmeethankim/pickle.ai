import Foundation
import FirebaseFunctions
import FirebaseFirestore

class AnalysisService {
    static let shared = AnalysisService()
    private init() {}

    private let functions = Functions.functions()
    private let db = Firestore.firestore()

    /// Calls the analyzeSwing Cloud Function, persists the result to Firestore, and returns the SwingAnalysis.
    func analyzeSwing(
        frames: [String],
        userId: String,
        videoUrl: String,
        videoDuration: Double,
        shotType: String? = nil
    ) async throws -> SwingAnalysis {
        let callable = functions.httpsCallable("analyzeSwing")

        var payload: [String: Any] = [
            "frames": frames,
            "userId": userId,
            "videoDuration": videoDuration,
        ]
        if let shotType = shotType {
            payload["shotType"] = shotType
        }

        let result = try await callable.call(payload)

        guard let data = result.data as? [String: Any] else {
            throw AnalysisError.invalidResponse
        }

        let feedback = try decodeFeedback(from: data)

        let overallScore = data["overallScore"] as? Int ?? 0

        var analysis = SwingAnalysis(
            createdAt: Date(),
            videoUrl: videoUrl,
            videoDurationSeconds: videoDuration,
            frameCount: frames.count,
            status: .completed,
            overallScore: overallScore,
            feedback: feedback,
            isPickleball: true,
            shotType: shotType.flatMap { ShotType(rawValue: $0) },
            errorMessage: nil
        )

        // Persist to Firestore
        let collectionRef = db.collection("users").document(userId).collection("analyses")
        let docRef = try collectionRef.addDocument(from: analysis)
        analysis.id = docRef.documentID

        return analysis
    }

    // MARK: - Decoding helpers

    private func decodeFeedback(from data: [String: Any]) throws -> CoachingFeedback {
        let reservedKeys: Set<String> = ["isPickleball", "overallScore", "generalTips"]
        var categories: [String: CategoryFeedback] = [:]

        for (key, _) in data {
            guard !reservedKeys.contains(key) else { continue }
            if let categoryData = data[key] as? [String: Any] {
                let score = categoryData["score"] as? Int ?? 0
                let tips = categoryData["tips"] as? [String] ?? []
                let timestamp = categoryData["timestamp"] as? Double ?? 0
                categories[key] = CategoryFeedback(score: score, tips: tips, timestamp: timestamp)
            }
        }

        let generalTips = data["generalTips"] as? [String] ?? []
        return CoachingFeedback(categories: categories, generalTips: generalTips)
    }
}

enum AnalysisError: LocalizedError {
    case invalidResponse
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the analysis service."
        case .missingField(let field):
            return "Missing expected field '\(field)' in analysis response."
        }
    }
}
