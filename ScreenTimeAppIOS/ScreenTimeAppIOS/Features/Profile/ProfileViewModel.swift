//
//  ProfileViewModel.swift
//  ScreenTimeAppIOS
//

import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var profile: Profile?
    var friendsCount = 0
    var isLoading = false
    var errorMessage: String?

    private let service: SupabaseService

    init() {
        self.service = SupabaseService()
    }

    init(service: SupabaseService) {
        self.service = service
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            async let profile = service.getCurrentProfile()
            async let friends = service.getFriends()

            self.profile = try await profile
            self.friendsCount = try await friends.count
        } catch {
            errorMessage = "Failed to load profile."
            print("DEBUG: Failed to load profile: \(error)")
        }

        isLoading = false
    }

    func updateUsername(_ username: String) async {
        do {
            profile = try await service.updateCurrentUsername(username)
        } catch {
            errorMessage = "Failed to update username."
            print("DEBUG: Failed to update username: \(error)")
        }
    }
}
