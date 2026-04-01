import Foundation
import SwiftUI
import AVFoundation

@MainActor
final class MatchAnalysisViewModel: ObservableObject {

    enum MatchAnalysisState {
        case idle
        case extractingFrames(progress: Double)
        case uploading
        case analyzing
        case completed(MatchAnalysis)
        case failed(Error)
    }

    enum MatchAnalysisError: LocalizedError {
        case frameExtractionFailed
        case uploadFailed(underlying: Error)
        case apiFailed(underlying: Error)
        case invalidVideoURL

        var errorDescription: String? {
            switch self {
            case .frameExtractionFailed:
                return "Could not extract frames from the video. Please try a different clip."
            case .uploadFailed(let err):
                return "Upload failed: \(err.localizedDescription)"
            case .apiFailed(let err):
                return "Analysis failed: \(err.localizedDescription)"
            case .invalidVideoURL:
                return "The video URL is invalid."
            }
        }
    }

    @Published var analysisState: MatchAnalysisState = .idle

    func analyzeMatch(url: URL, userId: String) async {
        analysisState = .extractingFrames(progress: 0)

        // Step 1: Extract frames at 0.5fps for longer match videos
        let frameDataArray: [Data]
        do {
            frameDataArray = try await FrameExtractor.extractFrames(
                from: url,
                fps: 0.5,
                progress: { [weak self] current, total in
                    Task { @MainActor in
                        let fraction = total > 0 ? Double(current) / Double(total) : 0
                        self?.analysisState = .extractingFrames(progress: fraction)
                    }
                }
            )
        } catch {
            analysisState = .failed(MatchAnalysisError.frameExtractionFailed)
            return
        }

        // Step 2: Upload video
        analysisState = .uploading
        let videoData: Data
        do {
            videoData = try Data(contentsOf: url)
        } catch {
            analysisState = .failed(MatchAnalysisError.invalidVideoURL)
            return
        }

        let storageUrl: String
        do {
            storageUrl = try await StorageService.shared.uploadVideo(videoData, userId: userId)
        } catch {
            analysisState = .failed(MatchAnalysisError.uploadFailed(underlying: error))
            return
        }

        // Step 3: Get video duration
        let asset = AVURLAsset(url: url)
        let duration: Double
        do {
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
        } catch {
            duration = Double(frameDataArray.count) * 2.0 // 0.5fps fallback
        }

        // Step 4: Run match analysis
        analysisState = .analyzing
        let base64Frames = frameDataArray.map { $0.base64EncodedString() }
        do {
            let result = try await MatchAnalysisService.shared.analyzeMatch(
                frames: base64Frames,
                userId: userId,
                videoUrl: storageUrl,
                videoDuration: duration
            )
            analysisState = .completed(result)
        } catch {
            analysisState = .failed(MatchAnalysisError.apiFailed(underlying: error))
        }
    }

    var isLoading: Bool {
        switch analysisState {
        case .extractingFrames, .uploading, .analyzing: return true
        default: return false
        }
    }

    var loadingMessage: String {
        switch analysisState {
        case .extractingFrames(let progress):
            return "Extracting frames… \(Int(progress * 100))%"
        case .uploading:
            return "Uploading video…"
        case .analyzing:
            return "AI is analyzing your match…"
        default:
            return ""
        }
    }
}
