import Foundation
import FirebaseFirestore
import FirebaseAuth

enum TimeRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case all = "All"

    var cutoffDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week:        return calendar.date(byAdding: .day, value: -7, to: Date())
        case .month:       return calendar.date(byAdding: .day, value: -30, to: Date())
        case .threeMonths: return calendar.date(byAdding: .day, value: -90, to: Date())
        case .all:         return nil
        }
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var analyses: [SwingAnalysis] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var selectedShotType: ShotType? = nil
    @Published var selectedTimeRange: TimeRange = .all

    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20

    var filteredAnalyses: [SwingAnalysis] {
        analyses.filter { analysis in
            let passesShot = selectedShotType == nil || analysis.shotType == selectedShotType
            let passesTime: Bool
            if let cutoff = selectedTimeRange.cutoffDate {
                passesTime = analysis.createdAt >= cutoff
            } else {
                passesTime = true
            }
            return passesShot && passesTime
        }
    }

    var totalAnalyses: Int { filteredAnalyses.count }

    var averageScore: Double? {
        let scored = filteredAnalyses.compactMap { $0.overallScore }
        guard !scored.isEmpty else { return nil }
        return Double(scored.reduce(0, +)) / Double(scored.count)
    }

    func load() async {
        guard !isLoading, let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        lastDocument = nil
        hasMore = true

        do {
            let query = db.collection("users").document(userId).collection("analyses")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)

            let snapshot = try await query.getDocuments()
            analyses = snapshot.documents.compactMap { try? $0.data(as: SwingAnalysis.self) }
            lastDocument = snapshot.documents.last
            hasMore = snapshot.documents.count == pageSize
        } catch {
            print("HistoryViewModel load error: \(error)")
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMore, let userId = Auth.auth().currentUser?.uid,
              let lastDoc = lastDocument else { return }
        isLoading = true

        do {
            let query = db.collection("users").document(userId).collection("analyses")
                .order(by: "createdAt", descending: true)
                .start(afterDocument: lastDoc)
                .limit(to: pageSize)

            let snapshot = try await query.getDocuments()
            let newAnalyses = snapshot.documents.compactMap { try? $0.data(as: SwingAnalysis.self) }
            analyses.append(contentsOf: newAnalyses)
            lastDocument = snapshot.documents.last
            hasMore = snapshot.documents.count == pageSize
        } catch {
            print("HistoryViewModel loadMore error: \(error)")
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }
}
