import SwiftUI
import Charts

struct ProgressChartView: View {
    let analyses: [SwingAnalysis]
    @State private var selectedCategory: String?

    private var chartData: [(date: Date, score: Int)] {
        analyses
            .compactMap { a -> (Date, Int)? in
                guard let score = a.overallScore else { return nil }
                return (a.createdAt, score)
            }
            .sorted { $0.0 < $1.0 }
    }

    private var categoryData: [(category: String, date: Date, score: Int)] {
        guard let category = selectedCategory else { return [] }
        return analyses
            .compactMap { a -> (String, Date, Int)? in
                guard let feedback = a.feedback else { return nil }
                let match = feedback.allCategories.first { $0.name == category }
                guard let cat = match else { return nil }
                return (category, a.createdAt, cat.feedback.score)
            }
            .sorted { $0.1 < $1.1 }
    }

    private var categories: [String] {
        guard let first = analyses.first(where: { $0.feedback != nil }),
              let feedback = first.feedback else { return [] }
        return feedback.allCategories.map { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.title2.bold())
                .padding(.horizontal)

            if chartData.count < 2 {
                emptyState
            } else {
                overallChart
                if !categories.isEmpty {
                    categoryPicker
                    if selectedCategory != nil && categoryData.count >= 2 {
                        categoryChart
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Need at least 2 analyses to show progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var overallChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Score")
                .font(.headline)
                .padding(.horizontal)

            Chart(chartData, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(.blue)
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(.blue)
            }
            .chartYScale(domain: 1...10)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5, 7, 10])
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button(category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedCategory == category ? .blue : .secondary)
                }
            }
            .padding(.horizontal)
        }
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedCategory ?? "")
                .font(.headline)
                .padding(.horizontal)

            Chart(categoryData, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(.orange)
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(.orange)
            }
            .chartYScale(domain: 1...10)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5, 7, 10])
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
    }
}
