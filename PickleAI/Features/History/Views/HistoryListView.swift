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

    private var analysesList: some View {
        List {
            Section {
                summaryHeader
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            ForEach(viewModel.analyses) { analysis in
                NavigationLink(destination: Text("Analysis Detail")) {
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
        case 8...10: return .green
        case 5...7:  return .yellow
        default:     return .red
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
