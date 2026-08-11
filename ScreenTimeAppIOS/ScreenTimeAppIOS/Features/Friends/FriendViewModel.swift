//
//  FriendViewModel.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class FriendViewModel {
    var friends: [Profile] = []
    var pendingRequests: [Friendship] = []
    var pendingRequestProfilesByID: [UUID: Profile] = [:]
    var searchResults: [Profile] = []
    var isLoading = false
    var errorMessage: String?

    private let service: SupabaseService

    init() {
        self.service = SupabaseService()
    }

    init(service: SupabaseService) {
        self.service = service
    }

    var friendsCount: Int {
        friends.count
    }

    var hasPendingRequests: Bool {
        !pendingRequests.isEmpty
    }

    func loadFriendsScreen() async {
        isLoading = true
        errorMessage = nil

        do {
            async let friends = service.getFriends()
            async let pendingRequests = service.getPendingFriendRequests()

            self.friends = try await friends
            self.pendingRequests = try await pendingRequests
            self.pendingRequestProfilesByID = try await loadProfilesByID(
                self.pendingRequests.map(\.requesterID)
            )
        } catch {
            errorMessage = "Failed to load friends."
            print("DEBUG: Failed to load friends screen: \(error)")
        }

        isLoading = false
    }

    func usernameForPendingRequest(_ request: Friendship) -> String {
        pendingRequestProfilesByID[request.requesterID]?.username ?? "Unknown user"
    }

    func searchProfiles(usernameQuery: String) async {
        let trimmedQuery = usernameQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }

        do {
            searchResults = try await service.searchProfiles(usernameQuery: trimmedQuery)
        } catch {
            errorMessage = "Failed to search profiles."
            print("DEBUG: Failed to search profiles: \(error)")
        }
    }

    func sendFriendRequest(to profile: Profile) async {
        do {
            _ = try await service.sendFriendRequest(to: profile.id)
            searchResults.removeAll { $0.id == profile.id }
        } catch {
            errorMessage = "Failed to send friend request."
            print("DEBUG: Failed to send friend request: \(error)")
        }
    }

    func acceptFriendRequest(_ request: Friendship) async {
        do {
            _ = try await service.acceptFriendRequest(id: request.id)
            await loadFriendsScreen()
        } catch {
            errorMessage = "Failed to accept friend request."
            print("DEBUG: Failed to accept friend request: \(error)")
        }
    }

    func rejectFriendRequest(_ request: Friendship) async {
        do {
            _ = try await service.rejectFriendRequest(id: request.id)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = "Failed to reject friend request."
            print("DEBUG: Failed to reject friend request: \(error)")
        }
    }

    func removeFriend(_ profile: Profile) async {
        do {
            let friendships = try await service.getAcceptedFriendships()
            guard let friendship = friendships.first(where: { friendship in
                friendship.requesterID == profile.id || friendship.addresseeID == profile.id
            }) else {
                return
            }

            try await service.deleteFriendship(id: friendship.id)
            friends.removeAll { $0.id == profile.id }
        } catch {
            errorMessage = "Failed to remove friend."
            print("DEBUG: Failed to remove friend: \(error)")
        }
    }

    private func loadProfilesByID(_ ids: [UUID]) async throws -> [UUID: Profile] {
        var profilesByID: [UUID: Profile] = [:]

        for id in Set(ids) {
            profilesByID[id] = try await service.getProfile(id: id)
        }

        return profilesByID
    }
    
}
