import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var stateListener: AuthStateDidChangeListenerHandle?

    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }

    private override init() {
        super.init()
    }

    // MARK: - Auth State

    func addStateListener(_ handler: @escaping (FirebaseAuth.User?) -> Void) {
        stateListener = auth.addStateDidChangeListener { _, user in
            handler(user)
        }
    }

    func removeStateListener() {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let profileChange = result.user.createProfileChangeRequest()
        profileChange.displayName = displayName
        try await profileChange.commitChanges()

        let appUser = AppUser.new(email: email, displayName: displayName)
        try db.collection("users").document(uid).setData(from: appUser)
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Apple Sign-In

    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<Void, Error>?

    func signInWithApple() async throws {
        let nonce = randomNonce()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.appleSignInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = appleCredential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            Task { @MainActor in
                self.appleSignInContinuation?.resume(throwing: AuthError.invalidAppleCredential)
                self.appleSignInContinuation = nil
            }
            return
        }

        Task { @MainActor in
            guard let nonce = self.currentNonce else {
                self.appleSignInContinuation?.resume(throwing: AuthError.invalidAppleCredential)
                self.appleSignInContinuation = nil
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )

            do {
                let result = try await self.auth.signIn(with: credential)
                if let email = appleCredential.email {
                    let displayName = [
                        appleCredential.fullName?.givenName,
                        appleCredential.fullName?.familyName
                    ].compactMap { $0 }.joined(separator: " ")

                    let uid = result.user.uid
                    let docRef = self.db.collection("users").document(uid)
                    let snapshot = try await docRef.getDocument()
                    if !snapshot.exists {
                        let appUser = AppUser.new(
                            email: email,
                            displayName: displayName.isEmpty ? email : displayName
                        )
                        try docRef.setData(from: appUser)
                    }
                }
                self.appleSignInContinuation?.resume()
            } catch {
                self.appleSignInContinuation?.resume(throwing: error)
            }
            self.appleSignInContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.appleSignInContinuation?.resume(throwing: error)
            self.appleSignInContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidAppleCredential

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential:
            return "Unable to process Apple Sign-In credential."
        }
    }
}
