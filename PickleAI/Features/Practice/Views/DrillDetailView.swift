import SwiftUI
import SafariServices

struct DrillDetailView: View {
    let drill: Drill
    @State private var showingSafari = false
    @State private var isCompleted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        if let shotType = drill.shotType {
                            Text(shotType)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                        Label("\(drill.durationMinutes) min", systemImage: "clock")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())

                        if let reps = drill.reps {
                            Text("\(reps) reps")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }

                    Text(drill.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Watch Demo button
                if let videoUrl = drill.videoUrl, !videoUrl.isEmpty {
                    Button {
                        showingSafari = true
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Watch Demo")
                                    .font(.headline)
                                if let title = drill.videoTitle, !title.isEmpty {
                                    Text(title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal)
                    .sheet(isPresented: $showingSafari) {
                        if let url = URL(string: videoUrl) {
                            SafariView(url: url)
                                .ignoresSafeArea()
                        }
                    }
                }

                // Common Mistakes
                if let mistakes = drill.commonMistakes, !mistakes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Common Mistakes", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(mistakes, id: \.self) { mistake in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.subheadline)
                                        .padding(.top, 1)
                                    Text(mistake)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Progression Tips
                if let tips = drill.progressionTips, !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Progression Tips", systemImage: "arrow.up.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .frame(width: 22, height: 22)
                                        .background(Color.green)
                                        .foregroundStyle(.white)
                                        .clipShape(Circle())
                                        .padding(.top, 1)
                                    Text(tip)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Mark Complete button
                Button {
                    isCompleted.toggle()
                    print("Drill '\(drill.name)' marked \(isCompleted ? "complete" : "incomplete")")
                } label: {
                    Label(
                        isCompleted ? "Completed!" : "Mark Complete",
                        systemImage: isCompleted ? "checkmark.seal.fill" : "checkmark.seal"
                    )
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCompleted ? Color.green : Color(.systemGray5))
                    .foregroundStyle(isCompleted ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top)
        }
        .navigationTitle(drill.name)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Safari Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
