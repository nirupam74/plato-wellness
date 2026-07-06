//
//  SignInView.swift
//  Wellness App
//
//  Shown when no user is signed in. Sign in with Apple, or email and password.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isBusy = false

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6 && !isBusy
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                    .padding(.top, 40)

                SignInWithAppleButton(.signIn) { request in
                    auth.prepareRequest(request)
                } onCompletion: { result in
                    auth.handleCompletion(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)

                dividerRow

                emailForm

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Text("By continuing you agree to our terms and privacy policy.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Plato Wellness")
                .font(.largeTitle.bold())
            Text("Log once, see everything, understand your trends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var dividerRow: some View {
        HStack {
            Rectangle().fill(.quaternary).frame(height: 1)
            Text("or").font(.footnote).foregroundStyle(.secondary)
            Rectangle().fill(.quaternary).frame(height: 1)
        }
    }

    private var emailForm: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            SecureField("Password", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            Button {
                isBusy = true
                Task {
                    if isSignUp {
                        await auth.signUp(email: email, password: password)
                    } else {
                        await auth.signIn(email: email, password: password)
                    }
                    isBusy = false
                }
            } label: {
                Group {
                    if isBusy { ProgressView() } else { Text(isSignUp ? "Create account" : "Sign in") }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 24)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(!canSubmit)

            HStack {
                Button(isSignUp ? "Have an account? Sign in" : "New here? Create an account") {
                    isSignUp.toggle()
                    auth.errorMessage = nil
                }
                .font(.footnote)
                Spacer()
                if !isSignUp {
                    Button("Forgot password?") {
                        Task { await auth.sendPasswordReset(email: email) }
                    }
                    .font(.footnote)
                    .disabled(!email.contains("@"))
                }
            }
            .padding(.top, 2)
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
