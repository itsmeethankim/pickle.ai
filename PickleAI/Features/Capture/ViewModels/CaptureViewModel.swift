import Foundation
import SwiftUI

@MainActor
class CaptureViewModel: ObservableObject {
    @Published var selectedVideoURL: URL?
    @Published var isShowingCamera = false
    @Published var isShowingPicker = false
    @Published var isProcessing = false
    @Published var validationError: String?
    @Published var isReadyForAnalysis = false

    func selectFromCamera() {
        validationError = nil
        isReadyForAnalysis = false
        isShowingCamera = true
    }

    func selectFromLibrary() {
        validationError = nil
        isReadyForAnalysis = false
        isShowingPicker = true
    }

    func onVideoRecorded(_ url: URL) {
        isShowingCamera = false
        selectedVideoURL = url
        Task { await validateAndProcess() }
    }

    func onVideoSelected(_ url: URL) {
        selectedVideoURL = url
        Task { await validateAndProcess() }
    }

    func validateAndProcess() async {
        guard let url = selectedVideoURL else { return }
        isProcessing = true
        validationError = nil
        isReadyForAnalysis = false

        do {
            try await VideoValidator.validate(url: url)
            isReadyForAnalysis = true
        } catch {
            validationError = error.localizedDescription
            selectedVideoURL = nil
        }

        isProcessing = false
    }
}
