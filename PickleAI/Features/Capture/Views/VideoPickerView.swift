import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPickerView: View {
    @Binding var selectedVideoURL: URL?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .videos,
            photoLibrary: .shared()
        ) {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            loadVideo(from: newItem)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .alert("Could not load video", isPresented: .constant(loadError != nil)) {
            Button("OK") { loadError = nil }
        } message: {
            Text(loadError ?? "")
        }
    }

    private func loadVideo(from item: PhotosPickerItem) {
        isLoading = true
        loadError = nil
        Task {
            do {
                if let url = try await item.loadTransferable(type: VideoTransferable.self) {
                    await MainActor.run {
                        selectedVideoURL = url.url
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        loadError = "Unable to load the selected video."
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return VideoTransferable(url: copy)
        }
    }
}
