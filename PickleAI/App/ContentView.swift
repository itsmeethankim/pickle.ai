import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            RecordTab()
                .tabItem {
                    Label("Record", systemImage: "video.fill")
                }

            HistoryTab()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.green)
    }
}

struct RecordTab: View {
    @StateObject private var captureVM = CaptureViewModel()
    @StateObject private var analysisVM = AnalysisViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var analysisStartTime = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "figure.pickleball")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("Analyze Your Swing")
                    .font(.title2.bold())

                Text("Record a video or choose from your library to get AI coaching feedback.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            captureVM.isShowingCamera = true
                        } label: {
                            Label("Record Video", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }

                    Button {
                        captureVM.isShowingPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("PickleAI")
            .sheet(isPresented: $captureVM.isShowingCamera) {
                CameraView(
                    onVideoRecorded: { url in
                        captureVM.selectedVideoURL = url
                        captureVM.isShowingCamera = false
                        startAnalysis()
                    },
                    onCancel: {
                        captureVM.isShowingCamera = false
                    }
                )
            }
            .sheet(isPresented: $captureVM.isShowingPicker) {
                VideoPickerView(selectedVideoURL: $captureVM.selectedVideoURL)
                    .onChange(of: captureVM.selectedVideoURL) { _, newURL in
                        if newURL != nil {
                            captureVM.isShowingPicker = false
                            startAnalysis()
                        }
                    }
            }
            .fullScreenCover(isPresented: showingAnalysis) {
                analysisOverlay
            }
            .alert("Validation Error", isPresented: showingError) {
                Button("OK") {}
            } message: {
                Text(captureVM.validationError ?? "")
            }
        }
    }

    private var showingAnalysis: Binding<Bool> {
        Binding(
            get: {
                switch analysisVM.analysisState {
                case .idle: return false
                default: return true
                }
            },
            set: { _ in }
        )
    }

    private var showingError: Binding<Bool> {
        Binding(
            get: { captureVM.validationError != nil },
            set: { if !$0 { captureVM.validationError = nil } }
        )
    }

    @ViewBuilder
    private var analysisOverlay: some View {
        switch analysisVM.analysisState {
        case .idle:
            EmptyView()
        case .extractingFrames, .uploading, .analyzing:
            AnalysisLoadingView(startTime: analysisStartTime)
        case .completed(let analysis):
            NavigationStack {
                AnalysisResultView(analysis: analysis)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                analysisVM.analysisState = .idle
                            }
                        }
                    }
            }
        case .failed(let error):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text("Analysis Failed")
                    .font(.title2.bold())
                Text(error.localizedDescription)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Try Again") {
                    analysisVM.analysisState = .idle
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }

    private func startAnalysis() {
        guard let url = captureVM.selectedVideoURL,
              let userId = authViewModel.currentUser?.uid else { return }
        analysisStartTime = Date()
        Task {
            await analysisVM.analyzeVideo(url: url, userId: userId)
        }
    }
}

struct HistoryTab: View {
    var body: some View {
        NavigationStack {
            HistoryListView()
        }
    }
}

struct ProfileTab: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text(authViewModel.currentUser?.displayName ?? "Player")
                                .font(.headline)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
