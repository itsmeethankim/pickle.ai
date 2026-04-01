import SwiftUI

struct MatchReportView: View {
    let analysis: MatchAnalysis
    @State private var expandedSegmentId: UUID?

    private var keySegments: [MatchSegment] {
        analysis.segments.filter { $0.isKeyMoment }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                MatchScoreRingView(score: analysis.matchReport.overallScore)

                matchStrengthsWeaknessesSection

                timelineSection

                if !keySegments.isEmpty {
                    keyMomentsSection
                }

                segmentCardsSection

                recommendationsSection

                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .navigationTitle("Match Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Strengths & Weaknesses

    private var matchStrengthsWeaknessesSection: some View {
        VStack(spacing: 12) {
            if !analysis.matchReport.strengths.isEmpty {
                MatchListSection(
                    title: "Strengths",
                    icon: "star.fill",
                    color: .green,
                    items: analysis.matchReport.strengths
                )
            }
            if !analysis.matchReport.weaknesses.isEmpty {
                MatchListSection(
                    title: "Areas to Improve",
                    icon: "arrow.up.circle.fill",
                    color: .orange,
                    items: analysis.matchReport.weaknesses
                )
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MatchSectionLabel(title: "Rally Timeline")
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(analysis.segments) { segment in
                        let fraction = analysis.videoDurationSeconds > 0
                            ? CGFloat((segment.endTime - segment.startTime) / analysis.videoDurationSeconds)
                            : CGFloat(1.0 / Double(max(1, analysis.segments.count)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(segmentColor(segment).opacity(segment.isKeyMoment ? 1.0 : 0.65))
                            .frame(width: max(6, geo.size.width * fraction), height: 40)
                            .overlay(
                                segment.isKeyMoment
                                    ? RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                                    : nil
                            )
                    }
                }
            }
            .frame(height: 40)
            .padding(10)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func segmentColor(_ segment: MatchSegment) -> Color {
        switch segment.score {
        case 80...100: return .green
        case 50...79:  return .yellow
        default:       return .red
        }
    }

    // MARK: - Key Moments

    private var keyMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MatchSectionLabel(title: "Key Moments")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.matchReport.keyMoments, id: \.self) { moment in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.callout)
                            .padding(.top, 2)
                        Text(moment)
                            .font(.callout)
                    }
                }
            }
            .padding(16)
            .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Segment Cards

    private var segmentCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MatchSectionLabel(title: "Segment Breakdown")
            ForEach(analysis.segments) { segment in
                SegmentCard(
                    segment: segment,
                    isExpanded: expandedSegmentId == segment.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedSegmentId = expandedSegmentId == segment.id ? nil : segment.id
                        }
                    }
                )
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MatchSectionLabel(title: "Recommendations")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.matchReport.recommendations, id: \.self) { rec in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                            .padding(.top, 2)
                        Text(rec)
                            .font(.callout)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(16)
            .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Score Ring

private struct MatchScoreRingView: View {
    let score: Int

    private var color: Color {
        switch score {
        case 80...100: return .green
        case 50...79:  return .yellow
        default:       return .red
        }
    }

    private var label: String {
        switch score {
        case 80...100: return "Excellent Match"
        case 50...79:  return "Good Match"
        default:       return "Needs Work"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Match Score")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.2), value: score)
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("/ 100")
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

// MARK: - Timeline Block

private struct SegmentTimelineBlock: View {
    let segment: MatchSegment
    let totalDuration: Double

    private var widthFraction: CGFloat {
        guard totalDuration > 0 else { return 0.1 }
        return CGFloat((segment.endTime - segment.startTime) / totalDuration)
    }

    private var color: Color {
        switch segment.score {
        case 80...100: return .green
        case 50...79:  return .yellow
        default:       return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(segment.isKeyMoment ? 1.0 : 0.6))
                .overlay(
                    segment.isKeyMoment ?
                    RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                    : nil
                )
                .frame(width: max(8, geo.size.width * widthFraction))
        }
        .frame(height: 40)
    }
}

// MARK: - Segment Card

private struct SegmentCard: View {
    let segment: MatchSegment
    let isExpanded: Bool
    let onTap: () -> Void

    private var scoreColor: Color {
        switch segment.score {
        case 80...100: return .green
        case 50...79:  return .yellow
        default:       return .red
        }
    }

    private var timeLabel: String {
        let start = Int(segment.startTime)
        let end = Int(segment.endTime)
        return "\(start)s – \(end)s"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    if segment.isKeyMoment {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(segment.shotType.capitalized)
                            .font(.subheadline.bold())
                        Text(timeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(segment.score)")
                        .font(.headline.bold())
                        .foregroundStyle(scoreColor)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded, let feedback = segment.feedback {
                Divider().padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(feedback.allCategories, id: \.name) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(item.feedback.score)/10")
                                .font(.caption.bold())
                                .foregroundStyle(item.feedback.score >= 7 ? .green : item.feedback.score >= 5 ? .yellow : .red)
                        }
                        if !item.feedback.tips.isEmpty {
                            ForEach(item.feedback.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(tip)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 4)
                            }
                        }
                    }

                    if !feedback.generalTips.isEmpty {
                        ForEach(feedback.generalTips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(segment.isKeyMoment ? Color.yellow.opacity(0.4) : Color(UIColor.quaternaryLabel), lineWidth: 1)
        )
    }
}

// MARK: - Shared Subviews

private struct MatchListSection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.bold())
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .padding(.top, 5)
                    Text(item)
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct MatchSectionLabel: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
        }
    }
}
