import SwiftUI
import AVKit
import Combine

struct AnnotatedPlayerView: View {
    let videoUrl: String
    let feedback: CoachingFeedback

    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerCoordinator: PlayerCoordinator

    init(videoUrl: String, feedback: CoachingFeedback) {
        self.videoUrl = videoUrl
        self.feedback = feedback
        let tips = feedback.allCategories.flatMap { item in
            item.feedback.tips.map { tip in
                (name: item.name, tip: tip, timestamp: item.feedback.timestamp)
            }
        }.sorted { $0.timestamp < $1.timestamp }
        _playerCoordinator = StateObject(
            wrappedValue: PlayerCoordinator(videoUrl: videoUrl, tips: tips)
        )
    }

    private var allTips: [(name: String, tip: String, timestamp: Double)] {
        feedback.allCategories.flatMap { item in
            item.feedback.tips.map { tip in
                (name: item.name, tip: tip, timestamp: item.feedback.timestamp)
            }
        }.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Video player with overlay
                ZStack(alignment: .bottomLeading) {
                    VideoPlayer(player: playerCoordinator.player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .background(.black)

                    // Active callout overlay
                    if let callout = playerCoordinator.activeCallout {
                        CalloutBubble(category: callout.name, tip: callout.tip)
                            .padding(12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: playerCoordinator.activeCallout?.tip)

                // Play/pause controls bar
                PlayerControlsBar(coordinator: playerCoordinator)

                Divider()

                // Tips list
                ScrollViewReader { proxy in
                    List {
                        ForEach(allTips, id: \.timestamp) { item in
                            TipRow(
                                category: item.name,
                                tip: item.tip,
                                timestamp: item.timestamp,
                                isActive: playerCoordinator.activeCallout?.tip == item.tip
                            )
                            .id(item.timestamp)
                            .onTapGesture {
                                playerCoordinator.seek(to: item.timestamp)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: playerCoordinator.activeCallout?.tip) { _, newTip in
                        if let tip = newTip,
                           let match = allTips.first(where: { $0.tip == tip }) {
                            withAnimation {
                                proxy.scrollTo(match.timestamp, anchor: .center)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Annotated Playback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear {
                playerCoordinator.player.pause()
            }
        }
    }
}

// MARK: - PlayerCoordinator

@MainActor
final class PlayerCoordinator: ObservableObject {
    let player: AVPlayer
    @Published var activeCallout: (name: String, tip: String)?
    @Published var isPlaying = false

    private var timeObserverToken: Any?
    private var allTipEntries: [(name: String, tip: String, timestamp: Double)] = []

    init(videoUrl: String, tips: [(name: String, tip: String, timestamp: Double)]) {
        if let url = URL(string: videoUrl) {
            player = AVPlayer(url: url)
        } else {
            player = AVPlayer()
        }
        allTipEntries = tips
        setupTimeObserver()
    }

    func seek(to timestamp: Double) {
        let time = CMTime(seconds: timestamp, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        if !isPlaying {
            player.play()
            isPlaying = true
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let currentSeconds = time.seconds
            Task { @MainActor [weak self] in
                self?.updateCallout(for: currentSeconds)
            }
        }
    }

    private func updateCallout(for currentTime: Double) {
        let window: Double = 2.0
        if let match = allTipEntries.first(where: { abs($0.timestamp - currentTime) <= window }) {
            if activeCallout?.tip != match.tip {
                activeCallout = (name: match.name, tip: match.tip)
            }
        } else {
            if activeCallout != nil {
                activeCallout = nil
            }
        }
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }
}

// MARK: - Subviews

private struct CalloutBubble: View {
    let category: String
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.green)
                .tracking(0.8)
            Text(tip)
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct PlayerControlsBar: View {
    @ObservedObject var coordinator: PlayerCoordinator

    var body: some View {
        HStack {
            Spacer()
            Button {
                coordinator.togglePlayPause()
            } label: {
                Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .background(.background)
    }
}

private struct TipRow: View {
    let category: String
    let tip: String
    let timestamp: Double
    let isActive: Bool

    private var formattedTime: String {
        let total = Int(timestamp)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(formattedTime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.green)
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(tip)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }

            Spacer()

            if isActive {
                Image(systemName: "waveform")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isActive ? Color.green.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    AnnotatedPlayerView(
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        feedback: CoachingFeedback(
            categories: [
                "grip": CategoryFeedback(score: 8, tips: ["Relax your grip for touch shots"], timestamp: 3.0),
                "stance": CategoryFeedback(score: 7, tips: ["Widen your base slightly"], timestamp: 7.0),
                "swingPath": CategoryFeedback(score: 6, tips: ["Follow through to target"], timestamp: 12.0),
                "followThrough": CategoryFeedback(score: 9, tips: ["Great extension!"], timestamp: 17.0),
                "footwork": CategoryFeedback(score: 5, tips: ["Move feet earlier", "Stay on toes"], timestamp: 22.0),
            ],
            generalTips: ["Patient dink rallies win points"]
        )
    )
}
