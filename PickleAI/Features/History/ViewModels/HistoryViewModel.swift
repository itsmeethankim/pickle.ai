import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var analyses: [SwingAnalysis] = []
    @Published var isLoading = false
    @Published var hasMore = true

    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20

    var totalAnalyses: Int { analyses.count }

    var averageScore: Double? {
        let scored = analyses.compactMap { $0.overallScore }
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
