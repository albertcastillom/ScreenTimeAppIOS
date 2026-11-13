//
//  ResetPasswordView.swift
//  ScreenTimeAppIOS
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var password = ""
    @State private var confirmedPassword = ""

    private var passwordsMatch: Bool {
        password == confirmedPassword
    }

    var body: some View {
        ZStack {
            Constants.authSurfaceColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 80)

                    Image(systemName: "lock.rotation")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Constants.accentColor)
                        .accessibilityHidden(true)

                    Text("Choose a New Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.AuthPrimaryText)

                    Text("Use at least 6 characters and enter the same password twice.")
                        .font(.body)
                        .foregroundStyle(Constants.AuthPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    passwordField(
                        title: "New Password",
                        text: $password
                    )

                    passwordField(
                        title: "Confirm New Password",
                        text: $confirmedPassword
                    )

                    Button(action: updatePassword) {
                        Group {
                            if authManager.isUpdatingPassword {
                                ProgressView()
                            } else {
                                Text("Update Password")
                            }
                        }
                        .authPrimaryButtonStyle()
                    }
                    .disabled(authManager.isUpdatingPassword)

                    if let message = authManager.passwordResetError {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .accessibilityLabel("Password update error: \(message)")
                    }

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: password) { _, _ in
            authManager.clearPasswordResetFeedback()
        }
        .onChange(of: confirmedPassword) { _, _ in
            authManager.clearPasswordResetFeedback()
        }
    }
}

private extension ResetPasswordView {
    func passwordField(title: String, text: Binding<String>) -> some View {
        HStack {
            SecureField(title, text: text)
                .textContentType(.newPassword)
                .submitLabel(title == "New Password" ? .next : .done)

            if !password.isEmpty && !confirmedPassword.isEmpty {
                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(passwordsMatch ? Constants.accentColor : .red)
                    .accessibilityLabel(passwordsMatch ? "Passwords match" : "Passwords do not match")
            }
        }
        .authInputStyle()
    }

    func updatePassword() {
        Task {
            await authManager.updatePassword(
                password,
                confirmedPassword: confirmedPassword
            )
        }
    }
}

#Preview {
    ResetPasswordView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
