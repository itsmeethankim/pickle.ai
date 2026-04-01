import Foundation
import SwiftUI
import AVFoundation

@MainActor
final class AnalysisViewModel: ObservableObject {

    enum AnalysisState {
        case idle
        case extractingFrames(progress: Double)
        case uploading
        case analyzing
        case completed(SwingAnalysis)
        case failed(Error)
    }

    enum AnalysisError: LocalizedError {
        case notPickleball
        case frameExtractionFailed
        case uploadFailed(underlying: Error)
        case apiFailed(underlying: Error)
        case invalidVideoURL

        var errorDescription: String? {
            switch self {
            case .notPickleball:
                return "This video doesn't appear to contain pickleball content. Please upload a pickleball video."
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

    @Published var analysisState: AnalysisState = .idle

    // MARK: - Main flow

    func analyzeVideo(url: URL, userId: String, shotType: ShotType? = nil) async {
        analysisState = .extractingFrames(progress: 0)

        // Step 1: Extract frames
        let frameDataArray: [Data]
        do {
            frameDataArray = try await FrameExtractor.extractFrames(
                from: url,
                fps: 1.0,
                progress: { [weak self] current, total in
                    Task { @MainActor in
                        let fraction = total > 0 ? Double(current) / Double(total) : 0
                        self?.analysisState = .extractingFrames(progress: fraction)
                    }
                }
            )
        } catch {
            analysisState = .failed(AnalysisError.frameExtractionFailed)
            return
        }

        // Step 2: Upload video
        analysisState = .uploading
        let videoData: Data
        do {
            videoData = try Data(contentsOf: url)
        } catch {
            analysisState = .failed(AnalysisError.invalidVideoURL)
            return
        }

        let storageUrl: String
        do {
            storageUrl = try await StorageService.shared.uploadVideo(
                videoData,
                userId: userId
            )
        } catch {
            analysisState = .failed(AnalysisError.uploadFailed(underlying: error))
            return
        }

        // Step 3: Get video duration
        let asset = AVURLAsset(url: url)
        let duration: Double
        do {
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
        } catch {
            duration = Double(frameDataArray.count)
        }

        // Step 4: Run analysis
        analysisState = .analyzing
        let base64Frames = frameDataArray.map { $0.base64EncodedString() }
        do {
            let result = try await AnalysisService.shared.analyzeSwing(
                frames: base64Frames,
                userId: userId,
                videoUrl: storageUrl,
                videoDuration: duration,
                shotType: shotType?.rawValue
            )
            guard result.isPickleball else {
                analysisState = .failed(AnalysisError.notPickleball)
                return
            }
            analysisState = .completed(result)
        } catch {
            analysisState = .failed(AnalysisError.apiFailed(underlying: error))
        }
    }

    // MARK: - Convenience accessors

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
            return "AI is analyzing your swing…"
        default:
            return ""
        }
    }

    var completedAnalysis: SwingAnalysis? {
        if case .completed(let analysis) = analysisState { return analysis }
        return nil
    }

    var failureError: Error? {
        if case .failed(let error) = analysisState { return error }
        return nil
    }
}
