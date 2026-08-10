//
//  AuthManager.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/23/26.
//

import Foundation

@Observable @MainActor
final class AuthManager{
    private let service: SupabaseAuthService
    
    var authState: AuthenticationState = .notDetermined
    var isDeletingAccount = false
    var accountDeletionError: String?
    
    init(service: SupabaseAuthService) {
        self.service = service
    }
    
    func login(withEmail email: String, password: String) async{
        do{
            self.authState = try await service.login(withEmail: email, password: password)
        } catch{
            print("DEBUG: Error loggin in: \(error)")
        }
    }
    
    func signUp(withEmail email: String, password: String, username: String) async {
        do{
            self.authState = try await service.signUp(withEmail: email, password: password, username: username)
        }catch{
            print("DEBUG: Error Signing up: \(error)")
        }
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
}
