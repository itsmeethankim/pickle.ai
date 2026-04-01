import SwiftUI
import AVFoundation

struct HistoryListView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.analyses.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    analysesList
                }
            }
            .navigationTitle("History")
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No analyses yet")
                .font(.title2.bold())
            Text("Record or upload a video to get started.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var summaryHeader: some View {
        HStack(spacing: 24) {
            statView(title: "Total", value: "\(viewModel.totalAnalyses)")
            Divider().frame(height: 36)
            if let avg = viewModel.averageScore {
                statView(title: "Avg Score", value: String(format: "%.1f", avg))
            } else {
                statView(title: "Avg Score", value: "—")
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func statView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
    }

    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(range.rawValue) {
                    viewModel.selectedTimeRange = range
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    viewModel.selectedTimeRange == range
                        ? Color.green
                        : Color.secondary.opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(
                    viewModel.selectedTimeRange == range ? .white : .primary
                )
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var shotTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") {
                    viewModel.selectedShotType = nil
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    viewModel.selectedShotType == nil
                        ? Color.green
                        : Color.secondary.opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(viewModel.selectedShotType == nil ? .white : .primary)

                ForEach(ShotType.allCases, id: \.self) { shot in
                    Button(shot.displayName) {
                        viewModel.selectedShotType = viewModel.selectedShotType == shot ? nil : shot
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.selectedShotType == shot
                            ? Color.green
                            : Color.secondary.opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(viewModel.selectedShotType == shot ? .white : .primary)
                }
            }
            .padding(.horizontal)
        }
    }

    private var analysesList: some View {
        List {
            // Summary + filters
            Section {
                summaryHeader
                timeRangePicker
                shotTypeFilter
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Progress chart
            if viewModel.filteredAnalyses.count >= 2 {
                Section {
                    ProgressChartView(analyses: viewModel.filteredAnalyses)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Insights
            if viewModel.filteredAnalyses.count >= 2 {
                Section {
                    InsightsView(analyses: viewModel.filteredAnalyses)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Analysis list
            Section("Sessions") {
                ForEach(viewModel.filteredAnalyses) { analysis in
                    NavigationLink(destination: AnalysisResultView(analysis: analysis)) {
                        AnalysisRowView(analysis: analysis)
                    }
                    .task {
                        if analysis.id == viewModel.analyses.last?.id && viewModel.hasMore {
                            await viewModel.loadMore()
                        }
                    }
                }

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct AnalysisRowView: View {
    let analysis: SwingAnalysis
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.createdAt.relativeFormatted())
                    .font(.subheadline.bold())
                Text(analysis.createdAt.shortFormatted())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let shotType = analysis.shotType {
                    Text(shotType.displayName)
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            Spacer()
            if let score = analysis.overallScore {
                scoreView(score: score)
            }
        }
        .padding(.vertical, 4)
        .task { await loadThumbnail() }
    }

    private var thumbnailView: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
                    .overlay(Image(systemName: "video").foregroundStyle(.secondary))
            }
        }
        .frame(width: 64, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func scoreView(score: Int) -> some View {
        Text("\(score)")
            .font(.title2.bold())
            .foregroundStyle(scoreColor(score))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 50...79:  return .yellow
        default:       return .red
        }
    }

    private func loadThumbnail() async {
        guard let url = URL(string: analysis.videoUrl) else { return }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        guard let cgImage = try? await generator.image(at: time).image else { return }
        thumbnail = UIImage(cgImage: cgImage)
    }
}
