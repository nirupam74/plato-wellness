//
//  AuthManager.swift
//  Wellness App
//
//  Sign in with Apple bridged to Firebase Auth. Exposes the current user and a
//  uid the stores bind to. Uses the SwiftUI SignInWithAppleButton request /
//  completion hooks, with a nonce for replay protection.
//

import Foundation
import Observation
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFunctions

@Observable
final class AuthManager {
    var user: User?
    var errorMessage: String?

    var isSignedIn: Bool { user != nil }
    var uid: String? { user?.uid }

    private var currentNonce: String?
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email and password

    func signUp(email: String, password: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = "Password reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Permanently delete the account and all its data (Apple guideline 5.1.1(v)).
    /// The server removes Firestore data, Storage files, and the Auth user; we
    /// then sign out locally.
    @discardableResult
    func deleteAccount() async -> Bool {
        do {
            _ = try await Functions.functions().httpsCallable("deleteAccount").call()
            signOut()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Sign in with Apple (SwiftUI button hooks)

    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Could not read the Apple credential."
                return
            }
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: credential.fullName
            )
            Auth.auth().signIn(with: firebaseCredential) { [weak self] _, error in
                if let error { self?.errorMessage = error.localizedDescription }
            }
        }
    }

    // MARK: - Nonce helpers

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status == errSecSuccess {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }
}
