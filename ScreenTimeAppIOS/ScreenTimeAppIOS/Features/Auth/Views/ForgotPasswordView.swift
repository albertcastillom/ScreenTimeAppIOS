//
//  ForgotPasswordView.swift
//  ScreenTimeAppIOS
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    var body: some View {
        ZStack {
            Constants.authSurfaceColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 80)

                    Image(systemName: "envelope.badge")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Constants.accentColor)
                        .accessibilityHidden(true)

                    Text("Reset Your Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.AuthPrimaryText)

                    Text("Enter the email address for your account and we'll send you a password-reset link.")
                        .font(.body)
                        .foregroundStyle(Constants.AuthPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.send)
                        .authInputStyle()
                        .onSubmit(sendResetLink)

                    Button(action: sendResetLink) {
                        Group {
                            if authManager.isRequestingPasswordReset {
                                ProgressView()
                            } else {
                                Text("Send Reset Link")
                            }
                        }
                        .authPrimaryButtonStyle()
                    }
                    .disabled(authManager.isRequestingPasswordReset)

                    passwordResetFeedback

                    Button("Back to Login") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Constants.AuthPrimaryText)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden(authManager.isRequestingPasswordReset)
        .onAppear {
            authManager.clearPasswordResetFeedback()
        }
        .onChange(of: email) { _, _ in
            authManager.clearPasswordResetFeedback()
        }
    }
}

private extension ForgotPasswordView {
    @ViewBuilder
    var passwordResetFeedback: some View {
        if let message = authManager.passwordResetError {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityLabel("Password reset error: \(message)")
        } else if let message = authManager.passwordResetNotice {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(Constants.AuthPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    func sendResetLink() {
        Task {
            await authManager.requestPasswordReset(email: email)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environment(AuthManager(service: SupabaseAuthService()))
    }
}
