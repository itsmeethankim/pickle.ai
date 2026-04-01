import SwiftUI

struct AnalysisLoadingView: View {
    let startTime: Date

    private let tips = [
        "Did you know? The kitchen is a 7-foot non-volley zone on each side of the net.",
        "Pro tip: Keep your paddle face open for better dinks.",
        "The dink shot is the most important shot — master it first.",
        "Soft hands win rallies. Relax your grip for better touch shots.",
        "Stay out of no man's land — move quickly to the kitchen line.",
        "Third-shot drops are the key to transitioning from baseline to net.",
        "Watch your opponent's paddle angle, not their arm, to predict shots.",
        "A continental grip works great for both forehand and backhand dinks.",
        "Split step before every shot to stay balanced and ready.",
        "The sport was invented in 1965 on Bainbridge Island, Washington."
    ]

    @State private var tipIndex = 0
    @State private var elapsed: TimeInterval = 0
    @State private var tipOpacity: Double = 1.0

    private let estimatedDuration: TimeInterval = 30

    private var progress: Double {
        min(elapsed / estimatedDuration, 0.95)
    }

    private var timeRemainingText: String {
        let remaining = max(estimatedDuration - elapsed, 3)
        let seconds = Int(remaining)
        if seconds >= 60 {
            return "About \(seconds / 60)m remaining"
        }
        return "About \(seconds)s remaining"
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                Image(systemName: "figure.pickleball")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Analyzing Your Swing")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text(timeRemainingText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.green)
                        .frame(maxWidth: 280)
                        .animation(.easeInOut(duration: 1), value: progress)

                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    Text("Did you know?")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(tips[tipIndex])
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(tipOpacity)
                        .animation(.easeInOut(duration: 0.4), value: tipOpacity)
                        .frame(minHeight: 60, alignment: .center)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

                Spacer()

                Text("AI is reviewing your technique frame by frame")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer().frame(height: 20)
            }
        }
        .onAppear {
            startTimers()
        }
    }

    private func startTimers() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsed = Date().timeIntervalSince(startTime)
        }
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation { tipOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                tipIndex = (tipIndex + 1) % tips.count
                withAnimation { tipOpacity = 1 }
            }
        }
    }
}

#Preview {
    AnalysisLoadingView(startTime: Date())
}
