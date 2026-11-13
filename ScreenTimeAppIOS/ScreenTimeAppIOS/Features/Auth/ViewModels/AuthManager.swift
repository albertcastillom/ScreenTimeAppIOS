//
//  AuthManager.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/23/26.
//

import Foundation
import Supabase

@Observable @MainActor
final class AuthManager{
    private let service: SupabaseAuthService

    var authState: AuthenticationState = .notDetermined
    var isAuthenticating = false
    var authenticationError: String?
    var authenticationNotice: String?
    var isDeletingAccount = false
    var accountDeletionError: String?

    //passwrod recovery states
    var isRequestingPasswordReset = false
    var passwordResetError: String?
    var passwordResetNotice: String?
    var isPasswordRecoveryActive = false
    var isUpdatingPassword = false
    var shouldShowLogin = false

    init(service: SupabaseAuthService) {
        self.service = service
    }

    func login(withEmail email: String, password: String) async {
        guard !isAuthenticating else { return }

        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            authenticationError = "Enter your email address and password."
            return
        }
        guard Self.isValidEmail(email) else {
            authenticationError = "Enter a valid email address."
            return
        }

        beginAuthentication()
        defer { isAuthenticating = false }

        do {
            authState = try await service.login(withEmail: email, password: password)
        } catch {
            authenticationError = userMessage(for: error, operation: .login)
            print("DEBUG: Error logging in: \(error)")
        }
    }

    func signUp(
        withEmail email: String,
        password: String,
        confirmedPassword: String,
        username: String
    ) async {
        guard !isAuthenticating else { return }

        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if let validationMessage = signUpValidationMessage(
            email: email,
            password: password,
            confirmedPassword: confirmedPassword,
            username: username
        ) {
            authenticationError = validationMessage
            return
        }

        beginAuthentication()
        defer { isAuthenticating = false }

        do {
            switch try await service.signUp(withEmail: email, password: password, username: username) {
            case .authenticated:
                authState = .authenticated
            case .emailConfirmationRequired:
                authenticationNotice = "Check your email to confirm your account, then log in."
            }
        } catch {
            authenticationError = userMessage(for: error, operation: .signUp)
            print("DEBUG: Error Signing up: \(error)")
        }
    }

    func clearAuthenticationFeedback() {
        authenticationError = nil
        authenticationNotice = nil
    }

    func clearPasswordResetFeedback() {
        passwordResetError = nil
        passwordResetNotice = nil
    }

    func signOut() async {
        do {
            try await service.signOut()
            self.authState = .notAuthenticated
        }catch{
            print("DEBUG: Error Signing out: \(error)")
        }
    }


    func deleteAccount() async {
        guard !isDeletingAccount else { return }

        isDeletingAccount = true
        accountDeletionError = nil

        do {
            try await service.deleteAccount()
            authState = .notAuthenticated
        } catch {
            accountDeletionError = "We couldn't delete your account. Please try again."
            print("DEBUG: Error deleting account: \(error)")
        }

        isDeletingAccount = false
    }

    func getAuthState() async {
        do{
            self.authState = try await service.getAuthState()
        } catch {
            print("DEBUG: Failed to get auth state: \(error)")
        }
    }

    func requestPasswordReset(email: String) async{
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Self.isValidEmail(email) else {
            passwordResetError = "Enter a valid email address."
            return
        }

        guard !isRequestingPasswordReset else {return}

        isRequestingPasswordReset = true
        passwordResetError = nil
        passwordResetNotice = nil

        defer {isRequestingPasswordReset = false}

        do{
            try await service.requestPasswordReset(email: email)

            passwordResetNotice = "If an account exists for that email, a reset link is on its way."
        } catch {
            passwordResetError = userMessage(for: error, operation: .passwordReset)
        }
    }

    func handleAuthCallback(_ url: URL) async {
        guard url.scheme == "com.albertcastillo.commit",
              url.host == "reset-password" else {
            return
        }

        do {
            clearPasswordResetFeedback()
            try await service.session(from: url)
            isPasswordRecoveryActive = true
        } catch {
            passwordResetError = "This password-reset link is invalid or has expired"
        }
    }

    func updatePassword(
        _ password: String,
        confirmedPassword: String
    ) async {
        guard !isUpdatingPassword else { return }

        guard password == confirmedPassword else {
            passwordResetError = "Passwords do not match."
            return
        }

        guard password.count >= 6 else {
            passwordResetError = "Password must be at least 6 characters."
            return
        }

        isUpdatingPassword = true
        passwordResetError = nil
        defer { isUpdatingPassword = false }

        do {
            try await service.updatePassword(password)
        } catch {
            passwordResetError = userMessage(
                for: error,
                operation: .passwordUpdate
            )
            return
        }

        do {
            try await service.signOutLocally()
        } catch {
            print("DEBUG: Password updated, but local sign out failed: \(error)")
        }

        passwordResetNotice = nil
        isPasswordRecoveryActive = false
        shouldShowLogin = true
        authState = .notAuthenticated
        authenticationNotice =
            "Your password was updated. Log in with your new password."
    }
}

private extension AuthManager {
    static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && parts[0].isEmpty == false && parts[1].contains(".")
    }

    func beginAuthentication() {
        isAuthenticating = true
        authenticationError = nil
        authenticationNotice = nil
    }

    func signUpValidationMessage(
        email: String,
        password: String,
        confirmedPassword: String,
        username: String
    ) -> String? {
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty, !confirmedPassword.isEmpty else {
            return "Complete every field to create your account."
        }
        guard Self.isValidEmail(email) else {
            return "Enter a valid email address."
        }
        guard (3...30).contains(username.count) else {
            return "Username must be between 3 and 30 characters."
        }
        guard username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            return "Username can only contain letters, numbers, and underscores."
        }
        guard password.count >= 6 else {
            return "Password must be at least 6 characters."
        }
        guard password == confirmedPassword else {
            return "Passwords do not match."
        }
        return nil
    }

    func userMessage(for error: Error, operation: AuthenticationOperation) -> String {
        if let urlError = error as? URLError,
           [.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(urlError.code) {
            return "Check your internet connection and try again."
        }

        guard let authError = error as? AuthError else {
            return fallbackMessage(for: operation)
        }

        switch authError.errorCode {
        case .invalidCredentials, .userNotFound:
            return "The email or password is incorrect."
        case .emailNotConfirmed:
            return "Confirm your email address before logging in."
        case .weakPassword:
            return "Choose a stronger password and try again."
        case .userAlreadyExists, .emailExists:
            return "An account with this email already exists."
        case .overRequestRateLimit, .overEmailSendRateLimit:
            return "Too many attempts. Please wait a moment and try again."
        case .signupDisabled:
            return "New account creation is currently unavailable."
        default:
            return fallbackMessage(for: operation)
        }
    }

    func fallbackMessage(for operation: AuthenticationOperation) -> String {
        switch operation {
        case .login:
            return "We couldn't log you in. Please try again."
        case .signUp:
            return "We couldn't create your account. Check your details and try again."
        case .passwordReset:
            return "We couldn't send the reset email. Please try again."
        case .passwordUpdate:
            return "We couldn't update your password. Please try again."
        }
    }
}
