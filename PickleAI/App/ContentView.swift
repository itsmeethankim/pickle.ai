import SwiftUI
import UIKit
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                        OnboardingView {
                            hasCompletedOnboarding = true
                        }
                    }
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

            CoachTab()
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill")
                }

            PracticeTab()
                .tabItem {
                    Label("Practice", systemImage: "figure.run")
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

enum AnalysisMode: String, CaseIterable {
    case quickShot = "Quick Shot"
    case fullMatch = "Full Match"
}

struct RecordTab: View {
    @StateObject private var captureVM = CaptureViewModel()
    @StateObject private var analysisVM = AnalysisViewModel()
    @StateObject private var matchAnalysisVM = MatchAnalysisViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var analysisMode: AnalysisMode = .quickShot
    @State private var analysisStartTime = Date()
    @State private var selectedShotType: ShotType?
    @State private var isShowingShotPicker = false
    @State private var shotPickerSelection: ShotType = .general
    @State private var pendingCameraCapture = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: analysisMode == .quickShot ? "figure.pickleball" : "video.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text(analysisMode == .quickShot ? "Analyze Your Swing" : "Analyze Full Match")
                    .font(.title2.bold())

                Text(analysisMode == .quickShot
                     ? "Record a video or choose from your library to get AI coaching feedback."
                     : "Record or choose a full match video to get rally-by-rally analysis and coaching insights.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Picker("Mode", selection: $analysisMode) {
                    ForEach(AnalysisMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            pendingCameraCapture = true
                            if analysisMode == .quickShot {
                                isShowingShotPicker = true
                            } else {
                                captureVM.isShowingCamera = true
                            }
                        } label: {
                            Label("Record Video", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }

                    Button {
                        pendingCameraCapture = false
                        if analysisMode == .quickShot {
                            isShowingShotPicker = true
                        } else {
                            captureVM.isShowingPicker = true
                        }
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
            .sheet(isPresented: $isShowingShotPicker, onDismiss: {
                if pendingCameraCapture {
                    captureVM.isShowingCamera = true
                } else {
                    captureVM.isShowingPicker = true
                }
            }) {
                NavigationStack {
                    ScrollView {
                        ShotTypePickerView(selectedShotType: $shotPickerSelection) {
                            selectedShotType = shotPickerSelection
                            isShowingShotPicker = false
                        }
                        .padding()
                    }
                    .navigationTitle("Select Shot Type")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Skip") {
                                selectedShotType = nil
                                isShowingShotPicker = false
                            }
                        }
                    }
                }
            }
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
                if analysisMode == .fullMatch {
                    if case .idle = matchAnalysisVM.analysisState { return false }
                    return true
                }
                if case .idle = analysisVM.analysisState { return false }
                return true
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
        if analysisMode == .fullMatch {
            matchAnalysisOverlay
        } else {
            quickShotOverlay
        }
    }

    @ViewBuilder
    private var quickShotOverlay: some View {
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

    @ViewBuilder
    private var matchAnalysisOverlay: some View {
        switch matchAnalysisVM.analysisState {
        case .idle:
            EmptyView()
        case .extractingFrames, .uploading, .analyzing:
            AnalysisLoadingView(startTime: analysisStartTime)
        case .completed(let matchAnalysis):
            NavigationStack {
                MatchReportView(analysis: matchAnalysis)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                matchAnalysisVM.analysisState = .idle
                            }
                        }
                    }
            }
        case .failed(let error):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text("Match Analysis Failed")
                    .font(.title2.bold())
                Text(error.localizedDescription)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Try Again") {
                    matchAnalysisVM.analysisState = .idle
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
        if analysisMode == .fullMatch {
            Task {
                await matchAnalysisVM.analyzeMatch(url: url, userId: userId)
            }
        } else {
            Task {
                await analysisVM.analyzeVideo(url: url, userId: userId, shotType: selectedShotType)
            }
        }
    }
}

struct CoachTab: View {
    var body: some View {
        ConversationListView()
    }
}

struct PracticeTab: View {
    var body: some View {
        PracticeTabView()
    }
}

struct HistoryTab: View {
    var body: some View {
        HistoryListView()
    }
}

struct ProfileTab: View {
    var body: some View {
        ProfileView()
    }
}
