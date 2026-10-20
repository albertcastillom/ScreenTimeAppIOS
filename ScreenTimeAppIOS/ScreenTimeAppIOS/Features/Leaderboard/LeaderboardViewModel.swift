//
//  LeaderboardViewModel.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 10/17/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class LeaderboardViewModel {
    var myMinutes = 0
    var friendsMinutes = 0
    var profile: Profile?
    var sessionsCount = 0
    
    var isLoading = false
    var errorMessage: String?

    private let service: SupabaseService

    init() {
        self.service = SupabaseService()
    }

    init(service: SupabaseService) {
        self.service = service
    }

    func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil

        do {
            async let profile = service.getCurrentProfile()
            async let myTotalMinutes = service.getTotalUserFocusDuration()
            async let sessions = service.getTotalUserFocusSessions()

            self.profile = try await profile
            self.myMinutes = try await myTotalMinutes
            self.sessionsCount = try await sessions
        } catch {
            errorMessage = "Failed to load leaderboard."
            print("DEBUG: Failed to load leaderboard: \(error)")
        }

        isLoading = false
    }

}
