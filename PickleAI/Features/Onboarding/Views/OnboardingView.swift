import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage(
                icon: "figure.pickleball",
                title: "Welcome to PickleAI",
                subtitle: "Your personal AI sports coach, available 24/7 to help you reach the next level.",
                showGetStarted: false,
                onComplete: onComplete
            )
            .tag(0)

            OnboardingPage(
                icon: "video.badge.waveform.fill",
                title: "Record & Analyze",
                subtitle: "Film your swings and get instant AI-powered feedback on technique, form, and shot selection.",
                showGetStarted: false,
                onComplete: onComplete
            )
            .tag(1)

            OnboardingPage(
                icon: "figure.run",
                title: "Practice & Improve",
                subtitle: "Receive personalized practice plans and drills tailored to your skill level and focus areas.",
                showGetStarted: false,
                onComplete: onComplete
            )
            .tag(2)

            OnboardingPage(
                icon: "chart.line.uptrend.xyaxis",
                title: "Track Progress",
                subtitle: "Watch your game improve over time with detailed stats, achievements, and streak tracking.",
                showGetStarted: true,
                onComplete: onComplete
            )
            .tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .tint(.green)
        .background(Color(.systemBackground))
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String
    let showGetStarted: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .symbolEffect(.pulse)

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if showGetStarted {
                Button {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    onComplete()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            } else {
                Color.clear
                    .frame(height: 80)
                    .padding(.bottom, 48)
            }
        }
    }
}
