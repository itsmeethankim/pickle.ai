import SwiftUI

struct AnalysisResultView: View {
    let analysis: SwingAnalysis
    @State private var showingVideo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let score = analysis.overallScore {
                    OverallScoreView(score: score)
                }

                if !analysis.isPickleball {
                    BannerView(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        message: "This video doesn't appear to contain pickleball content. Results may be inaccurate."
                    )
                }

                if let error = analysis.errorMessage {
                    BannerView(
                        icon: "xmark.circle.fill",
                        color: .red,
                        message: error
                    )
                }

                if let feedback = analysis.feedback {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "Breakdown")
                        ForEach(feedback.allCategories, id: \.name) { item in
                            CategoryCardView(name: item.name, feedback: item.feedback)
                        }
                    }

                    if !feedback.generalTips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(title: "General Tips")
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(feedback.generalTips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.callout)
                                            .padding(.top, 2)
                                        Text(tip)
                                            .font(.callout)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .padding(16)
                            .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button {
                        showingVideo = true
                    } label: {
                        Label("Watch Annotated Video", systemImage: "play.circle.fill")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.green, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .fullScreenCover(isPresented: $showingVideo) {
                        AnnotatedPlayerView(videoUrl: analysis.videoUrl, feedback: feedback)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .navigationTitle("Swing Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Overall Score

private struct OverallScoreView: View {
    let score: Int

    private var color: Color {
        switch score {
        case 8...10: return .green
        case 5...7:  return .yellow
        default:     return .red
        }
    }

    private var label: String {
        switch score {
        case 8...10: return "Excellent"
        case 5...7:  return "Good"
        default:     return "Needs Work"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Score")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.2), value: score)
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("/ 10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)

            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(color.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Category Card

private struct CategoryCardView: View {
    let name: String
    let feedback: CategoryFeedback

    private var color: Color {
        switch feedback.score {
        case 8...10: return .green
        case 5...7:  return .yellow
        default:     return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text("\(feedback.score)/10")
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }

            ProgressView(value: Double(feedback.score), total: 10)
                .progressViewStyle(.linear)
                .tint(color)

            if !feedback.tips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(feedback.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(color)
                                .font(.caption.bold())
                                .padding(.top, 2)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}

// MARK: - Banner

private struct BannerView: View {
    let icon: String
    let color: Color
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .padding(14)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisResultView(analysis: SwingAnalysis(
            createdAt: Date(),
            videoUrl: "https://example.com/video.mp4",
            videoDurationSeconds: 30,
            frameCount: 60,
            status: .completed,
            overallScore: 7,
            feedback: CoachingFeedback(
                categories: [
                    "grip": CategoryFeedback(score: 8, tips: ["Maintain a loose grip"], timestamp: 2.5),
                    "stance": CategoryFeedback(score: 6, tips: ["Widen your base"], timestamp: 5.0),
                    "swingPath": CategoryFeedback(score: 7, tips: ["Follow through toward target"], timestamp: 8.0),
                    "followThrough": CategoryFeedback(score: 9, tips: ["Great extension!"], timestamp: 11.0),
                    "footwork": CategoryFeedback(score: 5, tips: ["Move feet earlier", "Stay on toes"], timestamp: 14.0),
                ],
                generalTips: ["Stay patient during dink rallies", "Work on your third-shot drop"]
            ),
            isPickleball: true,
            errorMessage: nil
        ))
    }
}
