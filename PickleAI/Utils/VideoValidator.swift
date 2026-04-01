import Foundation
import AVFoundation

enum ValidationError: LocalizedError {
    case tooLong(duration: Double, maxDuration: Double)
    case tooLarge(fileSize: Int64, maxFileSize: Int64)
    case unreadableFile
    case unreadableDuration

    var errorDescription: String? {
        switch self {
        case .tooLong(let duration, let max):
            let durationStr = String(format: "%.0f", duration)
            let maxStr = String(format: "%.0f", max)
            return "Video is too long (\(durationStr)s). Maximum allowed duration is \(maxStr) seconds."
        case .tooLarge(let fileSize, let maxFileSize):
            let fileMB = fileSize / (1024 * 1024)
            let maxMB = maxFileSize / (1024 * 1024)
            return "Video is too large (\(fileMB)MB). Maximum allowed size is \(maxMB)MB."
        case .unreadableFile:
            return "Could not read the video file."
        case .unreadableDuration:
            return "Could not determine video duration."
        }
    }
}

struct VideoValidator {
    static let maxDurationSeconds: Double = 60
    static let maxFileSizeBytes: Int64 = 100 * 1024 * 1024 // 100MB

    @discardableResult
    static func checkDuration(url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
        } catch {
            throw ValidationError.unreadableDuration
        }
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite else { throw ValidationError.unreadableDuration }
        if seconds > maxDurationSeconds {
            throw ValidationError.tooLong(duration: seconds, maxDuration: maxDurationSeconds)
        }
        return seconds
    }

    @discardableResult
    static func checkFileSize(url: URL) throws -> Int64 {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attrs[.size] as? Int64 else {
            throw ValidationError.unreadableFile
        }
        if fileSize > maxFileSizeBytes {
            throw ValidationError.tooLarge(fileSize: fileSize, maxFileSize: maxFileSizeBytes)
        }
        return fileSize
    }

    static func validate(url: URL) async throws -> (duration: Double, fileSize: Int64) {
        let fileSize = try checkFileSize(url: url)
        let duration = try await checkDuration(url: url)
        return (duration: duration, fileSize: fileSize)
    }
}
