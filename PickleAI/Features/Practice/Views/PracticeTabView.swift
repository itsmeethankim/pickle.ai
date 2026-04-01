import SwiftUI

struct PracticeTabView: View {
    @StateObject private var practiceVM = PracticeViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isShowingGeneratePlan = false

    var body: some View {
        NavigationStack {
            Group {
                if let plan = practiceVM.currentPlan {
                    planView(plan: plan)
                } else if practiceVM.isLoading {
                    ProgressView("Loading your plan…")
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Practice")
            .onAppear {
                if let userId = authViewModel.currentUser?.uid {
                    practiceVM.loadCurrentPlan(userId: userId)
                }
            }
            .sheet(isPresented: $isShowingGeneratePlan) {
                GeneratePlanView(practiceVM: practiceVM)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Get Your Practice Plan")
                .font(.title2.bold())

            Text("Generate a personalized 5-day practice plan based on your skill level and analysis history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                isShowingGeneratePlan = true
            } label: {
                Label("Create Plan", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    @ViewBuilder
    private func planView(plan: PracticePlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary
                Text(plan.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Day selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(plan.days.enumerated()), id: \.offset) { index, day in
                            Button {
                                practiceVM.selectedDayIndex = index
                            } label: {
                                Text(day.dayName)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(practiceVM.selectedDayIndex == index ? Color.green : Color(.systemGray5))
                                    .foregroundStyle(practiceVM.selectedDayIndex == index ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Drills for selected day
                if practiceVM.selectedDayIndex < plan.days.count {
                    let day = plan.days[practiceVM.selectedDayIndex]
                    VStack(spacing: 12) {
                        ForEach(day.drills) { drill in
                            DrillCard(drill: drill)
                        }
                    }
                    .padding(.horizontal)
                }

                Button {
                    isShowingGeneratePlan = true
                } label: {
                    Label("Generate New Plan", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
    }
}

struct DrillCard: View {
    let drill: Drill

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(drill.name)
                    .font(.headline)
                Spacer()
            }

            Text(drill.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(drill.durationMinutes) min", systemImage: "clock")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())

                if let shotType = drill.shotType {
                    Text(shotType)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }

                if let reps = drill.reps {
                    Text("\(reps) reps")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}
