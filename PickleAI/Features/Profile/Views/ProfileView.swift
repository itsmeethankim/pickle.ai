import SwiftUI
import FirebaseFirestore

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var progress = UserProgress()
    @Published var analysisCount = 0
    @Published var isLoading = false

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            progress = try await GamificationService.shared.loadProgress(userId: userId)
            let snapshot = try await Firestore.firestore()
                .collection("users").document(userId).getDocument()
            analysisCount = snapshot.data()?["analysisCount"] as? Int ?? 0
        } catch {
            // Keep defaults
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var skillLevel: Double = 3.0

    private var displayName: String {
        authViewModel.currentUser?.displayName ?? "Player"
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            let first = parts[0].first.map(String.init) ?? "P"
            let second = parts[1].first.map(String.init) ?? ""
            return first + second
        }
        return String(displayName.prefix(2)).uppercased()
    }

    var body: some View {
        NavigationStack {
            List {
                // Avatar + level header
                Section {
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.green.gradient)
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Text(initials)
                                        .font(.title.bold())
                                        .foregroundStyle(.white)
                                )

                            Text("Lv.\(vm.progress.level)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green, in: Capsule())
                                .offset(x: 4, y: 4)
                        }

                        VStack(spacing: 2) {
                            Text(displayName)
                                .font(.title3.bold())
                            Text(vm.progress.levelName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        // XP progress bar
                        VStack(spacing: 4) {
                            HStack {
                                Text("\(vm.progress.xp) XP")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                                Spacer()
                                Text("\(vm.progress.level * 500) XP")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: vm.progress.xpProgress)
                                .tint(.green)
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Stats row
                Section("Stats") {
                    HStack(spacing: 0) {
                        StatCell(icon: "flame.fill", color: .orange, value: "\(vm.progress.currentStreak)", label: "Streak")
                        Divider()
                        StatCell(icon: "video.fill", color: .green, value: "\(vm.analysisCount)", label: "Analyses")
                        Divider()
                        StatCell(icon: "trophy.fill", color: .yellow, value: "\(vm.progress.longestStreak)", label: "Best Streak")
                    }
                    .frame(maxWidth: .infinity)
                }

                // Navigation links
                Section("Progress") {
                    NavigationLink {
                        AchievementsView(progress: vm.progress)
                    } label: {
                        Label("Achievements", systemImage: "medal.fill")
                            .foregroundStyle(.primary)
                    }

                    NavigationLink {
                        WeeklyGoalsView(progress: $vm.progress)
                    } label: {
                        Label("Weekly Goals", systemImage: "target")
                            .foregroundStyle(.primary)
                    }
                }

                // Skill level
                Section("Skill Level") {
                    HStack {
                        Slider(value: $skillLevel, in: 2.0...5.0, step: 0.5)
                            .tint(.green)
                            .onChange(of: skillLevel) { _, newValue in
                                saveSkillLevel(newValue)
                            }
                        Text(skillLevel, format: .number.precision(.fractionLength(1)))
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                            .frame(width: 36, alignment: .trailing)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                guard let uid = authViewModel.currentUser?.uid else { return }
                await vm.load(userId: uid)
                loadSkillLevel()
            }
        }
    }

    private func saveSkillLevel(_ value: Double) {
        guard let userId = authViewModel.currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userId)
            .setData(["skillLevel": value], merge: true)
    }

    private func loadSkillLevel() {
        guard let userId = authViewModel.currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, _ in
            if let value = snapshot?.data()?["skillLevel"] as? Double {
                skillLevel = value
            }
        }
    }
}

private struct StatCell: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
