import SwiftUI

struct AchievementsView: View {
    let progress: UserProgress

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private func achievement(_ a: Achievement) -> Achievement {
        var copy = a
        if progress.unlockedAchievements.contains(a.id) {
            copy.unlockedAt = Date()
        }
        return copy
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Achievement.all) { a in
                    AchievementCard(achievement: achievement(a))
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: achievement.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(achievement.isUnlocked ? .green : .secondary)
                    .saturation(achievement.isUnlocked ? 1.0 : 0.0)
                    .frame(width: 56, height: 56)

                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .background(Color(.systemBackground), in: Circle())
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .background(Color(.systemBackground), in: Circle())
                }
            }

            VStack(spacing: 2) {
                Text(achievement.name)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(achievement.requirement)
                .font(.caption2.bold())
                .foregroundStyle(achievement.isUnlocked ? Color.green : Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (achievement.isUnlocked ? Color.green : Color.secondary).opacity(0.15),
                    in: Capsule()
                )
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}
