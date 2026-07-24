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
    
    init() {
        guard let projectURL = URL(string: AppConstants.projectURLString) else {
            preconditionFailure("Invalid Supabase project URL")
        }

        self.client = SupabaseClient(
            supabaseURL: projectURL,
            supabaseKey: AppConstants.projectAPIKey)
    }
    
    func login(withEmail email: String, password: String) async throws -> AuthenticationState{
        try await client.auth.signIn(email: email, password: password)
        return .authenticated
    }
    
    
    func signUp(withEmail email: String, password: String, username: String) async throws -> AuthenticationState{
        try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "username": .string(username),
            ]
        )
        return .authenticated
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getAuthState() async throws -> AuthenticationState{
        let user = try? await client.auth.session.user
        return user == nil ? .notAuthenticated : .authenticated
    }
}
