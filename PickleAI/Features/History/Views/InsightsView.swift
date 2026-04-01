import SwiftUI

struct InsightsView: View {
    let analyses: [SwingAnalysis]

    private var categoryAverages: [(name: String, avg: Double)] {
        var totals: [String: (sum: Int, count: Int)] = [:]
        for analysis in analyses {
            guard let feedback = analysis.feedback else { continue }
            for item in feedback.allCategories {
                let existing = totals[item.name] ?? (sum: 0, count: 0)
                totals[item.name] = (sum: existing.sum + item.feedback.score, count: existing.count + 1)
            }
        }
        return totals.map { name, value in
            (name: name, avg: Double(value.sum) / Double(value.count))
        }.sorted { $0.avg > $1.avg }
    }

    private var bestCategory: (name: String, avg: Double)? { categoryAverages.first }
    private var weakestCategory: (name: String, avg: Double)? { categoryAverages.last }

    private var improvementTrend: Double? {
        let scored = analyses.compactMap { $0.overallScore }
        guard scored.count >= 6 else { return nil }
        let recent = scored.prefix(5)
        let previous = scored.dropFirst(5).prefix(5)
        guard !previous.isEmpty else { return nil }
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let prevAvg = Double(previous.reduce(0, +)) / Double(previous.count)
        guard prevAvg > 0 else { return nil }
        return ((recentAvg - prevAvg) / prevAvg) * 100
    }

    private var practiceRecommendation: String? {
        guard let weakest = weakestCategory else { return nil }
        return "Focus on \(weakest.name) — your average is \(String(format: "%.0f", weakest.avg * 10))/100. Targeted drills can improve this quickly."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.title2.bold())
                .padding(.horizontal)

            VStack(spacing: 10) {
                if let best = bestCategory {
                    InsightCard(
                        icon: "star.fill",
                        iconColor: .green,
                        title: "Best Area",
                        value: best.name,
                        detail: String(format: "Avg %.0f/100", best.avg * 10)
                    )
                }

                if let weakest = weakestCategory {
                    InsightCard(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "Needs Work",
                        value: weakest.name,
                        detail: String(format: "Avg %.0f/100", weakest.avg * 10)
                    )
                }

                if let trend = improvementTrend {
                    InsightCard(
                        icon: trend >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        iconColor: trend >= 0 ? .green : .red,
                        title: "Recent Trend",
                        value: trend >= 0 ? "+\(String(format: "%.1f", trend))%" : "\(String(format: "%.1f", trend))%",
                        detail: "vs previous 5 sessions"
                    )
                }

                if let rec = practiceRecommendation {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommendation")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(rec)
                                .font(.callout)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}

private struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
        .padding(.horizontal)
    }
}
