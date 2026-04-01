import Foundation
import FirebaseStorage

class StorageService {
    static let shared = StorageService()
    private init() {}

    /// Uploads video data to Firebase Storage and returns the download URL.
    /// - Parameters:
    ///   - videoData: Raw video bytes
    ///   - userId: Owner's user ID
    ///   - progressHandler: Called with upload progress (0.0 – 1.0)
    /// - Returns: Download URL string
    func uploadVideo(
        _ videoData: Data,
        userId: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> String {
        let filename = UUID().uuidString + ".mov"
        let path = "videos/\(userId)/\(filename)"
        let ref = Storage.storage().reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = ref.putData(videoData, metadata: metadata) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                ref.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let url = url else {
                        continuation.resume(throwing: StorageError.missingDownloadURL)
                        return
                    }
                    continuation.resume(returning: url.absoluteString)
                }
            }

            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                let fraction = Double(progress.completedUnitCount) /
                               Double(progress.totalUnitCount)
                progressHandler?(fraction)
            }
        }
    }
}

enum StorageError: LocalizedError {
    case missingDownloadURL

    var errorDescription: String? {
        switch self {
        case .missingDownloadURL:
            return "Failed to retrieve download URL after upload."
        }
    }
}
