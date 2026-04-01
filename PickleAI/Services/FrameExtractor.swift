import Foundation
import AVFoundation
import UIKit

struct FrameExtractor {
    static func extractFrames(
        from url: URL,
        fps: Double = 1.0,
        progress: ((Int, Int) -> Void)? = nil
    ) async throws -> [Data] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds > 0 else { return [] }

        let frameCount = max(1, Int(durationSeconds * fps))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5 / fps, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5 / fps, preferredTimescale: 600)

        var times: [NSValue] = []
        for i in 0..<frameCount {
            let seconds = Double(i) / fps
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            times.append(NSValue(time: time))
        }

        return try await withCheckedThrowingContinuation { continuation in
            var frames: [(Int, Data)] = []
            var completed = 0
            var encounteredError: Error?

            generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, actualTime, result, error in
                let index = Int(CMTimeGetSeconds(requestedTime) * fps)

                switch result {
                case .succeeded:
                    if let cgImage {
                        let uiImage = UIImage(cgImage: cgImage)
                        if let data = uiImage.jpegData(compressionQuality: 0.8) {
                            frames.append((index, data))
                        }
                    }
                case .failed:
                    if encounteredError == nil, let error {
                        encounteredError = error
                    }
                case .cancelled:
                    break
                @unknown default:
                    break
                }

                completed += 1
                progress?(completed, frameCount)

                if completed == frameCount {
                    if let error = encounteredError, frames.isEmpty {
                        continuation.resume(throwing: error)
                    } else {
                        let sorted = frames.sorted { $0.0 < $1.0 }.map { $0.1 }
                        continuation.resume(returning: sorted)
                    }
                }
            }
        }
    }
}
