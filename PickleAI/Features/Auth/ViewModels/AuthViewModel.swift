import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = .shared) {
        self.authService = authService
        authService.addStateListener { [weak self] user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    // Note: listener is not removed in deinit because @MainActor methods
    // cannot be called from nonisolated deinit. The listener lives for the
    // app lifetime since AuthViewModel is created at the app root.

    // MARK: - Auth Actions

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signInWithApple()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
