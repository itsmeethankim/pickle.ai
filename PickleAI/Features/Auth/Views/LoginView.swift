import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "figure.tennis")
                                .font(.system(size: 64))
                                .foregroundStyle(.green)
                                .padding(.top, 48)

                            Text("PickleAI")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.primary)

                            Text("AI-powered pickleball coaching")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Form
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textFieldStyle(.appRounded)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()

                            SecureField("Password", text: $password)
                                .textFieldStyle(.appRounded)
                        }
                        .padding(.horizontal, 24)

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                Task { await viewModel.signIn(email: email, password: password) }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .buttonStyle(.appPrimary)
                            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                            .padding(.horizontal, 24)

                            Text("or")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { _ in
                                Task { await viewModel.signInWithApple() }
                            }
                            .frame(height: 50)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }

                        // Sign Up Link
                        Button {
                            showSignUp = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundStyle(.secondary)
                                Text("Sign Up")
                                    .foregroundStyle(.green)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Sign In Failed", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}


#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
