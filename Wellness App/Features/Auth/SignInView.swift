//
//  SignInView.swift
//  Wellness App
//
//  Shown when no user is signed in. Sign in with Apple only, per the spec.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Plato Wellness")
                    .font(.largeTitle.bold())
                Text("Log once, see everything, understand your trends.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                auth.prepareRequest(request)
            } onCompletion: { result in
                auth.handleCompletion(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .padding(.horizontal, 32)

            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("By continuing you agree to our terms and privacy policy.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom)
        }
        .padding()
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
