//
//  SupabaseAuthService.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/23/26.
//

import Foundation
import Supabase

struct SupabaseAuthService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func login(withEmail email: String, password: String) async throws -> AuthenticationState{
        try await client.auth.signIn(email: email, password: password)
        return .authenticated
    }


    func signUp(withEmail email: String, password: String, username: String) async throws -> SignUpResult {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "username": .string(username),
            ]
        )
        return response.session == nil ? .emailConfirmationRequired : .authenticated
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func signOutLocally() async throws {
        try await client.auth.signOut(scope: .local)
    }

    func deleteAccount() async throws {
        let _: DeleteAccountResponse = try await client.functions.invoke("delete-account")
        try await client.auth.signOut(scope: .local)
    }

    func getAuthState() async throws -> AuthenticationState{
        do{
            _ = try await client.auth.session
            return .authenticated
        } catch let error as AuthError{
            switch error.errorCode{
            case .sessionNotFound,
                    .sessionExpired,
                    .refreshTokenNotFound,
                    .refreshTokenAlreadyUsed:
                return .notAuthenticated
                
            default:
                throw error
            }
        }
    }
    
    //exposes Supabases event stream
    var authStateChanges: AsyncStream<(
        event: AuthChangeEvent,
        session: Session?
    )>{
        client.auth.authStateChanges
    }

    func requestPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(
                string: "com.albertcastillo.commit://reset-password"
            )!
        )
    }

    func session(from url: URL) async throws {
        _ = try await client.auth.session(from: url)
    }

    func updatePassword(_ password: String) async throws {
        try await client.auth.update(user: UserAttributes(password: password))
    }
}

enum SignUpResult {
    case authenticated
    case emailConfirmationRequired
}

nonisolated private struct DeleteAccountResponse: Decodable {
    let success: Bool
}
