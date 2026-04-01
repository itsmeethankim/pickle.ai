import SwiftUI
import UIKit
import UniformTypeIdentifiers
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    enum CameraPosition {
        case front, rear
    }

    var cameraPosition: CameraPosition = .rear
    var onVideoRecorded: (URL) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onVideoRecorded: onVideoRecorded, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoMaximumDuration = 60
        picker.videoQuality = .typeHigh
        picker.cameraDevice = cameraPosition == .front ? .front : .rear
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onVideoRecorded: (URL) -> Void
        var onCancel: () -> Void

        init(onVideoRecorded: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onVideoRecorded = onVideoRecorded
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let url = info[.mediaURL] as? URL {
                onVideoRecorded(url)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
