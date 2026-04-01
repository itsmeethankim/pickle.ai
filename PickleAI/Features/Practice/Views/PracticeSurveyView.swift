import SwiftUI

struct PracticeSurveyView: View {
    @ObservedObject var practiceVM: PracticeViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var skillLevel: Double = 3.0
    @State private var selectedShots: Set<ShotType> = []
    @State private var availableMinutes: Int = 45
    @State private var selectedGoal: String = "General Fitness"

    private let timeOptions = [15, 30, 45, 60]
    private let goalOptions = ["Tournament Prep", "Recreational Improvement", "Fix Specific Weakness", "General Fitness"]

    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                skillLevelStep.tag(0)
                shotWeaknessStep.tag(1)
                timeStep.tag(2)
                goalsStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                bottomBar
            }
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Skill Level"
        case 1: return "Shot Weaknesses"
        case 2: return "Available Time"
        case 3: return "Your Goals"
        default: return ""
        }
    }

    // MARK: - Step 1: Skill Level
    private var skillLevelStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("What's your skill level?")
                    .font(.title2.bold())
                Text("DUPR / self-rated level")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Text(String(format: "%.1f", skillLevel))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Slider(value: $skillLevel, in: 2.0...5.0, step: 0.5)
                    .tint(.green)
                    .padding(.horizontal, 32)

                HStack {
                    Text("2.0")
                    Spacer()
                    Text("5.0")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Step 2: Shot Weaknesses
    private var shotWeaknessStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Which shots need work?")
                    .font(.title2.bold())
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ShotType.allCases, id: \.self) { shot in
                    shotToggleButton(shot)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func shotToggleButton(_ shot: ShotType) -> some View {
        let isSelected = selectedShots.contains(shot)
        return Button {
            if isSelected {
                selectedShots.remove(shot)
            } else {
                selectedShots.insert(shot)
            }
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: shot.iconName)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white, .green)
                            .offset(x: 4, y: -4)
                    }
                }
                Text(shot.displayName)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.green.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .green : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Step 3: Available Time
    private var timeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("How long can you practice?")
                    .font(.title2.bold())
            }

            VStack(spacing: 12) {
                ForEach(timeOptions, id: \.self) { minutes in
                    Button {
                        availableMinutes = minutes
                    } label: {
                        HStack {
                            Image(systemName: availableMinutes == minutes ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(.green)
                            Text("\(minutes) minutes")
                                .font(.body.bold())
                            Spacer()
                        }
                        .padding()
                        .background(availableMinutes == minutes ? Color.green.opacity(0.1) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(availableMinutes == minutes ? Color.green : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 4: Goals
    private var goalsStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("What's your primary goal?")
                    .font(.title2.bold())
            }

            VStack(spacing: 12) {
                ForEach(goalOptions, id: \.self) { goal in
                    Button {
                        selectedGoal = goal
                    } label: {
                        HStack {
                            Image(systemName: selectedGoal == goal ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(.green)
                            Text(goal)
                                .font(.body.bold())
                            Spacer()
                        }
                        .padding()
                        .background(selectedGoal == goal ? Color.green.opacity(0.1) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedGoal == goal ? Color.green : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<4) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.green : Color(.systemGray4))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            if currentStep < 3 {
                Button {
                    withAnimation { currentStep += 1 }
                } label: {
                    Text("Next")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            } else {
                Button {
                    practiceVM.skillLevel = skillLevel
                    practiceVM.selectedFocusAreas = Set(selectedShots.map { $0.displayName })
                    Task {
                        await practiceVM.generatePlan(
                            userId: userId,
                            availableMinutes: availableMinutes,
                            goals: selectedGoal
                        )
                        dismiss()
                    }
                } label: {
                    if practiceVM.isGenerating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("Generate Plan")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .disabled(practiceVM.isGenerating)
                .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 32)
        .background(.ultraThinMaterial)
    }
}
