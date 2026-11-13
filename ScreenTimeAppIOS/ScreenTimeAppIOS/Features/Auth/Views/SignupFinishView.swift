//
//  SignupFinishView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/21/26.
//

import SwiftUI

struct SignupFinishView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var username = ""
    @State private var password = ""
    @State private var confirmedPassword = ""

    init(email: String) {
        _email = State(initialValue: email)
    }

    var body: some View {
        ZStack {
            Constants.authSurfaceColor.ignoresSafeArea()

            VStack {

                Spacer()

                Text("Finish Signing Up")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.AuthPrimaryText)
                Text("Please fill out the fields")
                    .font(.body)
                    .foregroundStyle(Constants.AuthPrimaryText)
                TextField("Enter your email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .authInputStyle()

                TextField("Enter your username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .authInputStyle()

                HStack {
                    SecureField("Enter your Password", text: $password)
                        .textContentType(.newPassword)

                    if !password.isEmpty && !confirmedPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? Constants.accentColor : .red)
                    }
                }
                .authInputStyle()

                HStack {
                    SecureField("Confirm your password", text: $confirmedPassword)
                        .textContentType(.newPassword)

                    if !password.isEmpty && !confirmedPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? Constants.accentColor : .red)
                    }
                }
                .authInputStyle()

                Button{
                    signUp()
                } label: {
                    Group {
                        if authManager.isAuthenticating {
                            ProgressView()
                        } else {
                            Text("Sign Up")
                        }
                    }
                    .authPrimaryButtonStyle()
                }
                .disabled(authManager.isAuthenticating)
                .padding(.vertical)

                authenticationFeedback

                Spacer()

                NavigationLink{
                    LoginView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3){
                        Text("Already have an account?")
                            .foregroundStyle(Constants.AuthPrimaryText)

                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundStyle(Constants.AuthPrimaryText)
                    }
                }
            }
        }
        .onChange(of: email) { _, _ in authManager.clearAuthenticationFeedback() }
        .onChange(of: username) { _, _ in authManager.clearAuthenticationFeedback() }
        .onChange(of: password) { _, _ in authManager.clearAuthenticationFeedback() }
        .onChange(of: confirmedPassword) { _, _ in authManager.clearAuthenticationFeedback() }
    }
}

private extension SignupFinishView{
    var passwordsMatch: Bool {
        password == confirmedPassword
    }

    @ViewBuilder
    var authenticationFeedback: some View {
        if let message = authManager.authenticationError {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityLabel("Sign up error: \(message)")
        } else if let message = authManager.authenticationNotice {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Constants.AuthPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    func signUp(){
        Task {
            await authManager.signUp(
                withEmail: email,
                password: password,
                confirmedPassword: confirmedPassword,
                username: username
            )
        }
    }
}

#Preview {
    SignupFinishView(email: "albert@example.com")
        .environment(AuthManager(service: SupabaseAuthService()))
}
