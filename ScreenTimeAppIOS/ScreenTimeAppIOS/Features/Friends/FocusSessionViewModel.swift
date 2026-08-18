//
//  FocusSessionViewModel.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 8/10/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class FocusSessionViewModel {
    // MARK: - View State

    var friends: [Profile] = []
    var pendingFocusSessions: [FocusRequest] = []
    var sentFocusSessions: [FocusRequest] = []

    var pendingRequestProfilesByID: [UUID: Profile] = [:]
    var sentRequestProfilesByID: [UUID: Profile] = [:]

    var selectedFriend: Profile?
    var selectedDurationMinutes: Int?

    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let service: SupabaseService

    // MARK: - Initialization

    init() {
        self.service = SupabaseService()
    }

    init(service: SupabaseService) {
        self.service = service
    }

    // MARK: - Derived State

    var hasPendingFocusSessions: Bool {
        !pendingFocusSessions.isEmpty
    }

    var hasSentFocusSessions: Bool {
        !sentFocusSessions.isEmpty
    }

    // MARK: - Screen Loading

    func loadFocusSessionScreen() async {
        isLoading = true
        errorMessage = nil

        do {
            async let friends = service.getFriends()
            async let incomingFocusSessions = service.getIncomingFocusRequests()
            async let outgoingFocusSessions = service.getOutgoingFocusRequests()

            self.friends = try await friends
            self.pendingFocusSessions = try await incomingFocusSessions.filter { $0.status == .pending }
            self.sentFocusSessions = try await outgoingFocusSessions.filter { $0.status == .pending }
            self.pendingRequestProfilesByID = try await loadProfilesByID(
                self.pendingFocusSessions.map(\.requesterID)
            )
            self.sentRequestProfilesByID = try await loadProfilesByID(
                self.sentFocusSessions.map(\.approverID)
            )
        } catch {
            errorMessage = "Failed to load focus sessions."
        }

        isLoading = false
    }

    // MARK: - Selection

    func selectFriend(_ friend: Profile) {
        selectedFriend = friend
    }

    func selectDuration(minutes: Int) {
        selectedDurationMinutes = minutes
    }

    // MARK: - Display Helpers

    func usernameForPendingFocusSessionRequest(_ request: FocusRequest) -> String {
        pendingRequestProfilesByID[request.requesterID]?.username ?? "Unknown user"
    }

    func usernameForSentFocusSessionRequest(_ request: FocusRequest) -> String {
        sentRequestProfilesByID[request.approverID]?.username ?? "Unknown user"
    }

    // MARK: - Send Requests

    func sendFocusSessionRequest() async {
        guard let selectedFriend else {
            errorMessage = "Choose a friend first."
            return
        }

        guard let selectedDurationMinutes else {
            errorMessage = "Choose a duration first."
            return
        }

        await sendFocusSessionRequest(selectedFriend.id, durationMinutes: selectedDurationMinutes)
    }

    func sendFocusSessionRequest(_ approverID: UUID, durationMinutes: Int) async {
        errorMessage = nil

        do {
            let request = try await service.createFocusRequest(
                approverID: approverID,
                durationMinutes: durationMinutes
            )
            sentFocusSessions.append(request)
            cacheSentProfileIfSelected(approverID: approverID)
        } catch {
            errorMessage = "Failed to send focus request."
        }
    }

    // MARK: - Incoming Request Actions

    func acceptFocusSessionRequest(_ request: FocusRequest) async {
        errorMessage = nil

        do {
            _ = try await service.acceptFocusRequest(id: request.id)
            pendingFocusSessions.removeAll { $0.id == request.id }
            removePendingProfileIfUnused(for: request.requesterID)
        } catch {
            errorMessage = "Failed to accept focus request."
        }
    }

    func rejectFocusSessionRequest(_ request: FocusRequest) async {
        errorMessage = nil

        do {
            _ = try await service.declineFocusRequest(id: request.id)
            pendingFocusSessions.removeAll { $0.id == request.id }
            removePendingProfileIfUnused(for: request.requesterID)
        } catch {
            errorMessage = "Failed to reject focus request."
        }
    }

    // MARK: - Outgoing Request Actions

    func cancelFocusSessionRequest(_ request: FocusRequest) async {
        errorMessage = nil

        do {
            _ = try await service.cancelFocusRequest(id: request.id)
            sentFocusSessions.removeAll { $0.id == request.id }
            removeSentProfileIfUnused(for: request.approverID)
        } catch {
            errorMessage = "Failed to cancel focus request."
        }
    }

    // MARK: - Private Helpers

    private func loadProfilesByID(_ ids: [UUID]) async throws -> [UUID: Profile] {
        var profilesByID: [UUID: Profile] = [:]

        for id in Set(ids) {
            profilesByID[id] = try await service.getProfile(id: id)
        }

        return profilesByID
    }

    private func cacheSentProfileIfSelected(approverID: UUID) {
        if let selectedFriend, selectedFriend.id == approverID {
            sentRequestProfilesByID[approverID] = selectedFriend
        }
    }

    private func removePendingProfileIfUnused(for requesterID: UUID) {
        if !pendingFocusSessions.contains(where: { $0.requesterID == requesterID }) {
            pendingRequestProfilesByID.removeValue(forKey: requesterID)
        }
    }

    private func removeSentProfileIfUnused(for approverID: UUID) {
        if !sentFocusSessions.contains(where: { $0.approverID == approverID }) {
            sentRequestProfilesByID.removeValue(forKey: approverID)
        }
    }
}
