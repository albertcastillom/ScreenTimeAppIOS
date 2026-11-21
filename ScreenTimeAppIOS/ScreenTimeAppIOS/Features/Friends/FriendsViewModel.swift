//
//  FriendsViewModel.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 8/3/26.
//

import Foundation
import Observation


enum FriendSearchResultState {
    case me
    case added
    case requested
    case incomingRequest
    case available
}

@Observable
@MainActor
final class FriendsViewModel {
    // MARK: - View State

    var friends: [Profile] = []
    var currentProfile: Profile?
    var pendingRequests: [Friendship] = []
    var outgoingPendingFriendIDs: Set<UUID> = []
    var pendingRequestProfilesByID: [UUID: Profile] = [:]
    var searchResults: [Profile] = []
    var isLoading = false
    var errorMessage: String?

    private let service: SupabaseService

    // MARK: - Initialization

    init() {
        self.service = SupabaseService()
    }

    init(service: SupabaseService) {
        self.service = service
    }

    // MARK: - Derived State

    var friendsCount: Int {
        friends.count
    }

    var hasPendingRequests: Bool {
        !pendingRequests.isEmpty
    }

    // MARK: - Screen Loading

    func loadFriendsScreen() async {
        isLoading = true
        errorMessage = nil

        do {
            async let friends = service.getFriends()
            async let pendingRequests = service.getPendingFriendRequests()
            async let outgoingRequests = service.getOutgoingPendingFriendRequests()
            async let currentProfile = service.getCurrentProfile()

            self.friends = try await friends
            self.pendingRequests = try await pendingRequests
            self.currentProfile = try await currentProfile
            
            let loadedOutgoingRequests = try await outgoingRequests
            outgoingPendingFriendIDs = Set(loadedOutgoingRequests.map(\.addresseeID))
            
            self.pendingRequestProfilesByID = try await loadProfilesByID(
                self.pendingRequests.map(\.requesterID)
            )
        } catch {
            errorMessage = "Failed to load friends."
        }

        isLoading = false
    }
    
    //invite url construction
    var inviteURL: URL? {
        guard let currentProfile else {
            return nil
        }

        return AppConstants.inviteBaseURL
            .appendingPathComponent("invite")
            .appendingPathComponent(
                currentProfile.id.uuidString.lowercased()
            )
    }

    // MARK: - Search

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
        }
    }
    
    func searchResultState(for profile: Profile) -> FriendSearchResultState {
        if profile.id == currentProfile?.id{
            return .me
        }
        
        if friends.contains(where: {$0.id == profile.id}){
            return .added
        }
        if outgoingPendingFriendIDs.contains(profile.id) {
                return .requested
            }

            if pendingRequests.contains(
                where: { $0.requesterID == profile.id }
            ) {
                return .incomingRequest
            }

            return .available
    }

    // MARK: - Pending Requests

    func usernameForPendingRequest(_ request: Friendship) -> String {
        pendingRequestProfilesByID[request.requesterID]?.username ?? "Unknown user"
    }

    func acceptFriendRequest(_ request: Friendship) async {
        do {
            _ = try await service.acceptFriendRequest(id: request.id)
            await loadFriendsScreen()
        } catch {
            errorMessage = "Failed to accept friend request."
        }
    }

    func rejectFriendRequest(_ request: Friendship) async {
        do {
            _ = try await service.rejectFriendRequest(id: request.id)
            pendingRequests.removeAll { $0.id == request.id }
            removePendingProfileIfUnused(for: request.requesterID)
        } catch {
            errorMessage = "Failed to reject friend request."
        }
    }

    // MARK: - Friend Actions

    func sendFriendRequest(to profile: Profile) async {
        //validation to prevent sending request to yourself or added friends or pending friends
        guard profile.id != currentProfile?.id else {
               return
           }

           guard !friends.contains(where: { $0.id == profile.id }) else {
               return
           }

           guard !outgoingPendingFriendIDs.contains(profile.id) else {
               return
           }

           guard !pendingRequests.contains(
               where: { $0.requesterID == profile.id }
           ) else {
               return
           }

        do {
            _ = try await service.sendFriendRequest(to: profile.id)
            searchResults.removeAll { $0.id == profile.id }
        } catch {
            errorMessage = "Failed to send friend request."
        }
    }

    func removeFriend(_ profile: Profile) async {
        do {
            guard let friendship = try await acceptedFriendship(with: profile) else {
                return
            }

            try await service.deleteFriendship(id: friendship.id)
            friends.removeAll { $0.id == profile.id }
        } catch {
            errorMessage = "Failed to remove friend."
        }
    }

    // MARK: - Helpers

    private func acceptedFriendship(with profile: Profile) async throws -> Friendship? {
        let friendships = try await service.getAcceptedFriendships()
        return friendships.first { friendship in
            friendship.requesterID == profile.id || friendship.addresseeID == profile.id
        }
    }

    private func loadProfilesByID(_ ids: [UUID]) async throws -> [UUID: Profile] {
        var profilesByID: [UUID: Profile] = [:]

        for id in Set(ids) {
            profilesByID[id] = try await service.getProfile(id: id)
        }

        return profilesByID
    }

    private func removePendingProfileIfUnused(for requesterID: UUID) {
        if !pendingRequests.contains(where: { $0.requesterID == requesterID }) {
            pendingRequestProfilesByID.removeValue(forKey: requesterID)
        }
    }
}
