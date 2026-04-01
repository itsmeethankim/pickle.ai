import Foundation
import FirebaseFunctions
import FirebaseFirestore

class PracticePlanService {
    static let shared = PracticePlanService()
    private init() {}

    private let functions = Functions.functions()
    private let db = Firestore.firestore()

    func generatePlan(userId: String, skillLevel: Double, focusAreas: [String], availableMinutes: Int = 45, goals: String = "General Improvement") async throws -> PracticePlan {
        let callable = functions.httpsCallable("generatePracticePlan")

        let payload: [String: Any] = [
            "userId": userId,
            "skillLevel": skillLevel,
            "focusAreas": focusAreas,
            "availableMinutes": availableMinutes,
            "goals": goals,
        ]

        let result = try await callable.call(payload)

        guard let data = result.data as? [String: Any] else {
            throw PracticePlanError.invalidResponse
        }

        let jsonData = try JSONSerialization.data(withJSONObject: data)
        var plan = try JSONDecoder().decode(PracticePlan.self, from: jsonData)

        // Save to Firestore
        let collectionRef = db.collection("users").document(userId).collection("plans")
        let docRef = try collectionRef.addDocument(from: plan)
        plan.id = docRef.documentID

        return plan
    }

    func loadCurrentPlan(userId: String) async throws -> PracticePlan? {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("plans")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first.map { doc in
            try doc.data(as: PracticePlan.self)
        }
    }

    func loadPlans(userId: String) async throws -> [PracticePlan] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("plans")
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments()

        return try snapshot.documents.map { doc in
            try doc.data(as: PracticePlan.self)
        }
    }
}

enum PracticePlanError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the practice plan service."
        }
    }
}
