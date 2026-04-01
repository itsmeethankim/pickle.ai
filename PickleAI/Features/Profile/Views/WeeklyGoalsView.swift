import SwiftUI

struct WeeklyGoalsView: View {
    @Binding var progress: UserProgress
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAddGoal = false
    @State private var newGoalType: WeeklyGoal.GoalType = .analyses
    @State private var newGoalTarget: Int = 5

    private var currentWeekOf: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return formatter.string(from: startOfWeek)
    }

    var body: some View {
        List {
            if progress.weeklyGoals.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("No Goals Yet")
                            .font(.headline)
                        Text("Set weekly goals to stay on track and earn achievements.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                Section("This Week") {
                    ForEach(progress.weeklyGoals) { goal in
                        GoalRow(goal: goal)
                    }
                }
            }

            Section {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Weekly Goals")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(
                goalType: $newGoalType,
                target: $newGoalTarget,
                onAdd: { addGoal() }
            )
        }
    }

    private func addGoal() {
        let goal = WeeklyGoal(type: newGoalType, target: newGoalTarget, weekOf: currentWeekOf)
        progress.weeklyGoals.append(goal)
        showingAddGoal = false

        guard let userId = authViewModel.currentUser?.uid else { return }
        Task {
            try? await GamificationService.shared.saveProgress(progress, userId: userId)
        }
    }
}

private struct GoalRow: View {
    let goal: WeeklyGoal

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 48, height: 48)
                    .animation(.easeInOut, value: goal.progress)
                Image(systemName: goal.type.icon)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.type.rawValue)
                    .font(.subheadline.bold())
                HStack {
                    Text("\(goal.current) / \(goal.target)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            Text("\(Int(goal.progress * 100))%")
                .font(.caption.bold())
                .foregroundStyle(goal.isCompleted ? .green : .secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AddGoalSheet: View {
    @Binding var goalType: WeeklyGoal.GoalType
    @Binding var target: Int
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Type") {
                    Picker("Type", selection: $goalType) {
                        ForEach(WeeklyGoal.GoalType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Weekly Target") {
                    Stepper("\(target)", value: $target, in: 1...100)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { onAdd() }
                        .bold()
                        .foregroundStyle(.green)
                }
            }
        }
    }
}
