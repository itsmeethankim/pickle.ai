import Foundation
import SwiftUI

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var currentPlan: PracticePlan?
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var skillLevel: Double = 3.0
    @Published var selectedFocusAreas: Set<String> = []
    @Published var selectedDayIndex: Int = 0

    var focusAreaOptions: [String] {
        ShotType.allCases.map { $0.displayName } + ["Strategy", "Consistency", "Fitness"]
    }

    func loadCurrentPlan(userId: String) {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                currentPlan = try await PracticePlanService.shared.loadCurrentPlan(userId: userId)
            } catch {
                print("Failed to load plan: \(error.localizedDescription)")
            }
        }
    }

    func generatePlan(userId: String) async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let plan = try await PracticePlanService.shared.generatePlan(
                userId: userId,
                skillLevel: skillLevel,
                focusAreas: Array(selectedFocusAreas)
            )
            currentPlan = plan
        } catch {
            print("Failed to generate plan: \(error.localizedDescription)")
        }
    }
}
