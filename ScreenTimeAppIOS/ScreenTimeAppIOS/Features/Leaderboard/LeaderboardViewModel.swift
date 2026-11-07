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
    var selectedPeriod: LeaderboardPeriod = .week
    var friendLeaderboard: [LeaderboardEntry] = []
    var globalLeaderboard: [LeaderboardEntry] = []
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
            async let friendLeaderboard = service.getFriendLeaderboard(period: selectedPeriod)
            async let globalLeaderboard = service.getGlobalLeaderboard(period: selectedPeriod)
            async let sessions = service.getTotalUserFocusSessions()

            let (loadedProfile, loadedFriends, loadedGlobal, loadedSessions) = try await (
                profile,
                friendLeaderboard,
                globalLeaderboard,
                sessions
            )

            self.profile = loadedProfile
            self.friendLeaderboard = loadedFriends
            self.globalLeaderboard = loadedGlobal
            self.myMinutes = loadedFriends.first(where: {
                $0.profileID == loadedProfile.id
            })?.totalMinutes ?? 0
            self.friendsMinutes = loadedFriends
                .filter { $0.profileID != loadedProfile.id }
                .reduce(0) { $0 + $1.totalMinutes }
            self.sessionsCount = loadedSessions
        } catch {
            errorMessage = "Failed to load leaderboard."
            print("DEBUG: Failed to load leaderboard: \(error)")
        }

        isLoading = false
    }

    func selectPeriod(_ period: LeaderboardPeriod) async {
        guard selectedPeriod != period else { return }

        selectedPeriod = period
        await loadLeaderboard()
    }

}
