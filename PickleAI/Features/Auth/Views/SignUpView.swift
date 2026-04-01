import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    private var passwordTooShort: Bool { !password.isEmpty && password.count < 6 }
    private var formValid: Bool {
        !email.isEmpty && password.count >= 6 && !displayName.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                        .padding(.top, 32)

                    Text("Create Account")
                        .font(.title.bold())

                    Text("Join PickleAI and improve your game")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(.appRounded)
                        .textInputAutocapitalization(.words)

                    TextField("Email", text: $email)
                        .textFieldStyle(.appRounded)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    VStack(alignment: .leading, spacing: 6) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.appRounded)

                        if passwordTooShort {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.leading, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Create Account Button
                Button {
                    Task { await viewModel.signUp(email: email, password: password, displayName: displayName) }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.appPrimary)
                .disabled(viewModel.isLoading || !formValid)
                .padding(.horizontal, 24)

                // Back to Login
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Text("Sign In")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Up Failed", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
