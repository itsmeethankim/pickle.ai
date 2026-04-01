import SwiftUI

struct GeneratePlanView: View {
    @ObservedObject var practiceVM: PracticeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("2.0 Beginner")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("5.0 Pro")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $practiceVM.skillLevel, in: 2.0...5.0, step: 0.5)
                            .tint(.green)
                        Text("Level \(practiceVM.skillLevel, specifier: "%.1f")")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Skill Level")
                }

                Section {
                    ForEach(practiceVM.focusAreaOptions, id: \.self) { area in
                        HStack {
                            Text(area)
                            Spacer()
                            if practiceVM.selectedFocusAreas.contains(area) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if practiceVM.selectedFocusAreas.contains(area) {
                                practiceVM.selectedFocusAreas.remove(area)
                            } else {
                                practiceVM.selectedFocusAreas.insert(area)
                            }
                        }
                    }
                } header: {
                    Text("Focus Areas")
                }

                Section {
                    Button {
                        Task {
                            guard let userId = authViewModel.currentUser?.uid else { return }
                            await practiceVM.generatePlan(userId: userId)
                            if !practiceVM.isGenerating {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if practiceVM.isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(practiceVM.isGenerating ? "Generating…" : "Generate Plan")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(practiceVM.selectedFocusAreas.isEmpty || practiceVM.isGenerating)
                    .listRowBackground(
                        practiceVM.selectedFocusAreas.isEmpty ? Color(.systemGray4) : Color.green
                    )
                    .foregroundStyle(
                        practiceVM.selectedFocusAreas.isEmpty ? Color(.systemGray) : .white
                    )
                }
            }
            .navigationTitle("Create Practice Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
