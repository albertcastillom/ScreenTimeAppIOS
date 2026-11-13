//
//  LoginView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/21/26.
//

import SwiftUI

struct LoginView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            Constants.authSurfaceColor.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Commit: Social App Blocker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.AuthPrimaryText)
                Spacer()

                Text("Login")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.AuthPrimaryText)
                TextField("Email Address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .authInputStyle()

                SecureField("Enter your password", text: $password)
                    .textContentType(.password)
                    .authInputStyle()

                Button{
                        login()
                } label: {
                    Group {
                        if authManager.isAuthenticating {
                            ProgressView()
                        } else {
                            Text("Login")
                        }
                    }
                    .authPrimaryButtonStyle()
                }
                .disabled(authManager.isAuthenticating)
                .padding(.vertical)

                NavigationLink("Forgot Password?") {
                    ForgotPasswordView()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Constants.AuthPrimaryText)

                authenticationFeedback

                Spacer()

                Button { dismiss() } label: {
                    HStack(spacing: 3){
                        Text("Don't have an account?")
                            .foregroundStyle(Constants.AuthPrimaryText)
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundStyle(Constants.AuthPrimaryText)
                        }
                }
            }
        }
        .onChange(of: email) { _, _ in authManager.clearAuthenticationFeedback() }
        .onChange(of: password) { _, _ in authManager.clearAuthenticationFeedback() }
    }
}

private extension LoginView{
    @ViewBuilder
    var authenticationFeedback: some View {
        if let message = authManager.authenticationError {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityLabel("Login error: \(message)")
        } else if let message = authManager.authenticationNotice {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Constants.AuthPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    func login(){
        Task {
            await authManager.login(withEmail: email, password: password)
        }
    }
}



#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthManager(service: SupabaseAuthService()))
    }
}
