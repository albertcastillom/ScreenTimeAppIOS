//
//  dbService.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 8/3/26.
//

import Foundation
import Supabase

// MARK: - Profile Models

nonisolated struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var createdAt: Date?
    var showOnGlobalLeaderboard: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case createdAt = "created_at"
        case showOnGlobalLeaderboard = "show_on_global_leaderboard"
    }
}

// MARK: - Friendship Models

nonisolated enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
    case blocked
}

nonisolated struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterID: UUID
    let addresseeID: UUID
    var status: FriendshipStatus
    var createdAt: Date?
    var respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case addresseeID = "addressee_id"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

// MARK: - Focus Request Models

nonisolated enum FocusRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
    case activated
    case completed
    case completedEarly = "completed_early"
    case cancelled
    case expired
    case failed
}

nonisolated struct FocusRequest: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterID: UUID
    let approverID: UUID
    let durationMinutes: Int
    var status: FocusRequestStatus
    var createdAt: Date?
    var respondedAt: Date?
    var activatedAt: Date?
    var endsAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case approverID = "approver_id"
        case durationMinutes = "duration_minutes"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case activatedAt = "activated_at"
        case endsAt = "ends_at"
    }
}

// MARK: - Focus Session Models

nonisolated enum FocusSessionSource: String, Codable {
    case local
    case friendRequest = "friend_request"
}

nonisolated enum FocusSessionStatus: String, Codable {
    case active
    case completed
    case completedEarly = "completed_early"
}

nonisolated struct FocusSession: Codable, Identifiable, Equatable {
    let id: UUID
    let userID: UUID
    let focusRequestID: UUID?
    let source: FocusSessionSource
    let status: FocusSessionStatus
    let activatedAt: Date
    let scheduledEndsAt: Date
    let endedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case focusRequestID = "focus_request_id"
        case source
        case status
        case activatedAt = "activated_at"
        case scheduledEndsAt = "scheduled_ends_at"
        case endedAt = "ended_at"
    }
}

// MARK: - Supabase Service

struct SupabaseService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    // MARK: Profiles
    func getCurrentProfile() async throws -> Profile {
        try await getProfile(id: currentUserID())
    }

    func getProfile(id: UUID) async throws -> Profile {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func searchProfiles(usernameQuery: String) async throws -> [Profile] {
        try await client
            .from("profiles")
            .select()
            .ilike("username", pattern: "%\(usernameQuery)%")
            .execute()
            .value
    }

    func updateCurrentUsername(_ username: String) async throws -> Profile {
        try await updateProfile(id: currentUserID(), username: username)
    }

    func updateProfile(id: UUID, username: String? = nil) async throws -> Profile {
        let payload = ProfileUpdatePayload(username: username)

        return try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func updateGlobalLeaderboardVisibility(_ isVisible: Bool) async throws {
        let userID = try await currentUserID()

        try await client
            .from("profiles")
            .update(["show_on_global_leaderboard": isVisible])
            .eq("id", value: userID.uuidString)
            .execute()
    }

    func deleteProfile(id: UUID) async throws {
        try await client
            .from("profiles")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: Friendships - Reads

    func getFriends() async throws -> [Profile] {
        let currentUserID = try await currentUserID()
        let friendships = try await getAcceptedFriendships(for: currentUserID)
        let friendIDs = friendships.map { friendship in
            friendship.requesterID == currentUserID ? friendship.addresseeID : friendship.requesterID
        }

        var friends: [Profile] = []
        for friendID in friendIDs {
            friends.append(try await getProfile(id: friendID))
        }
        return friends
    }
    
    func getAcceptedFriendsCount() async throws -> Int {
        let userID = try await currentUserID()
        
        let response = try await client
            .from("friendships")
            .select("*", head: true, count: .exact)
            .or("requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString)")
            .eq("status", value: FriendshipStatus.accepted.rawValue)
            .execute()
        
        return response.count ?? 0
    }

    func getAcceptedFriendships(for userID: UUID? = nil) async throws -> [Friendship] {
        let userID = try await resolvedUserID(userID)

        return try await client
            .from("friendships")
            .select()
            .or("requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString)")
            .eq("status", value: FriendshipStatus.accepted.rawValue)
            .execute()
            .value
    }

    func getPendingFriendRequests() async throws -> [Friendship] {
        let userID = try await currentUserID()

        return try await client
            .from("friendships")
            .select()
            .eq("addressee_id", value: userID.uuidString)
            .eq("status", value: FriendshipStatus.pending.rawValue)
            .execute()
            .value
    }

    // MARK: Friendships - Writes

    func sendFriendRequest(to addresseeID: UUID) async throws -> Friendship {
        let payload = FriendshipInsertPayload(
            requesterID: try await currentUserID(),
            addresseeID: addresseeID,
            status: .pending
        )

        return try await client
            .from("friendships")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func acceptFriendRequest(id: UUID) async throws -> Friendship {
        try await updateFriendshipStatus(id: id, status: .accepted)
    }

    func rejectFriendRequest(id: UUID) async throws -> Friendship {
        try await updateFriendshipStatus(id: id, status: .declined)
    }

    func deleteFriendship(id: UUID) async throws {
        try await client
            .from("friendships")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    private func updateFriendshipStatus(id: UUID, status: FriendshipStatus) async throws -> Friendship {
        let payload = FriendshipStatusUpdatePayload(status: status)

        return try await client
            .from("friendships")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: Focus Requests - Reads

    func getIncomingFocusRequests() async throws -> [FocusRequest] {
        let userID = try await currentUserID()

        return try await client
            .from("focus_requests")
            .select()
            .eq("approver_id", value: userID.uuidString)
            .execute()
            .value
    }

    func getOutgoingFocusRequests() async throws -> [FocusRequest] {
        let userID = try await currentUserID()

        return try await client
            .from("focus_requests")
            .select()
            .eq("requester_id", value: userID.uuidString)
            .execute()
            .value
    }

    func getAcceptedOutgoingFocusRequests() async throws -> [FocusRequest] {
        let userID = try await currentUserID()

        return try await client
            .from("focus_requests")
            .select()
            .eq("requester_id", value: userID.uuidString)
            .eq("status", value: FocusRequestStatus.accepted.rawValue)
            .execute()
            .value
    }
    
    func getTotalUserFocusSessions() async throws -> Int {
        let userID = try await currentUserID()
        
        let response = try await client
            .from("focus_requests")
            .select(head: true, count: .exact)
            .eq("requester_id", value: userID.uuidString)
            .eq("status", value: FocusRequestStatus.activated.rawValue)
            .execute()
            
        return response.count ?? 0
    }
    
    func getTotalUserFocusDuration() async throws -> Int {
        let userID = try await currentUserID()
        
        let totalDuration: Int = try await client
            .rpc("get_user_total_focus_duration", params: ["target_user_id": userID.uuidString])
            .execute()
            .value
        
        return totalDuration
    }
    // MARK: Focus Requests - Writes

    func createFocusRequest(approverID: UUID, durationMinutes: Int) async throws -> FocusRequest {
        let payload = FocusRequestInsertPayload(
            requesterID: try await currentUserID(),
            approverID: approverID,
            durationMinutes: durationMinutes,
            status: .pending,
        )

        return try await client
            .from("focus_requests")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func acceptFocusRequest(id: UUID) async throws -> FocusRequest {
        try await client
            .rpc("accept_focus_request", params: FocusRequestRPCPayload(requestID: id))
            .single()
            .execute()
            .value
    }

    func declineFocusRequest(id: UUID) async throws -> FocusRequest {
        try await client
            .rpc("decline_focus_request", params: FocusRequestRPCPayload(requestID: id))
            .single()
            .execute()
            .value
    }

    func activateFocusRequest(id: UUID) async throws -> FocusRequest {
        try await client
            .rpc("mark_focus_request_activated", params: FocusRequestRPCPayload(requestID: id))
            .single()
            .execute()
            .value
    }

    func cancelFocusRequest(id: UUID) async throws -> FocusRequest {
        try await client
            .rpc("cancel_focus_request", params: FocusRequestRPCPayload(requestID: id))
            .single()
            .execute()
            .value
    }

    // MARK: Focus Sessions

    func startLocalFocusSession(durationMinutes: Int) async throws -> FocusSession {
        try await client
            .rpc(
                "start_local_focus_session",
                params: StartLocalFocusSessionRPCPayload(durationMinutes: durationMinutes)
            )
            .single()
            .execute()
            .value
    }

    func endFocusSessionEarly(id: UUID) async throws -> FocusSession {
        try await client
            .rpc("end_focus_session_early", params: FocusSessionRPCPayload(sessionID: id))
            .single()
            .execute()
            .value
    }

    func reconcileElapsedFocusSession(id: UUID) async throws -> FocusSession {
        try await client
            .rpc("reconcile_elapsed_focus_session", params: FocusSessionRPCPayload(sessionID: id))
            .single()
            .execute()
            .value
    }

    // MARK: Focus Requests - realtime

    func acceptedFocusRequestUpdates() async throws -> AsyncThrowingStream<FocusRequest, Error> {
        let requesterID = try await currentUserID()
        let topic = "focus_requests:\(requesterID.uuidString.lowercased())"
        let channel = client.realtimeV2.channel(topic) {
            // Database broadcasts are private and realtime messages
            $0.isPrivate = true
        }
        let updates = channel.broadcastStream(event: "UPDATE")
        try await channel.subscribeWithError()

        return AsyncThrowingStream { continuation in
            let task = Task {
                for await message in updates {
                    guard let request = decodeAcceptedFocusRequest(from: message) else {
                        continue
                    }
                    continuation.yield(request)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
                Task {
                    await channel.unsubscribe()
                }
            }
        }
    }

    private func decodeAcceptedFocusRequest(from message: JSONObject) -> FocusRequest? {
        guard let payload = message["payload"],
              let data = try? JSONEncoder().encode(payload),
              let change = try? JSONDecoder().decode(FocusRequestBroadcastPayload.self, from: data),
              change.record.status == .accepted else {
            return nil
        }

        return change.record.focusRequest
    }

    // MARK: Helpers

    private func resolvedUserID(_ userID: UUID?) async throws -> UUID {
        if let userID {
            return userID
        }

        return try await currentUserID()
    }

    private func currentUserID() async throws -> UUID {
        try await client.auth.session.user.id
    }
}

// MARK: - Request Payloads

nonisolated private struct ProfileUpdatePayload: Encodable {
    let username: String?

    enum CodingKeys: String, CodingKey {
        case username
    }
}

nonisolated private struct FriendshipInsertPayload: Encodable {
    let requesterID: UUID
    let addresseeID: UUID
    let status: FriendshipStatus

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
        case addresseeID = "addressee_id"
        case status
    }
}

nonisolated private struct FriendshipStatusUpdatePayload: Encodable {
    let status: FriendshipStatus

    enum CodingKeys: String, CodingKey {
        case status
    }
}

nonisolated private struct FocusRequestInsertPayload: Encodable {
    let requesterID: UUID
    let approverID: UUID
    let durationMinutes: Int
    let status: FocusRequestStatus

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
        case approverID = "approver_id"
        case durationMinutes = "duration_minutes"
        case status
    }
}

nonisolated private struct FocusRequestRPCPayload: Encodable {
    let requestID: UUID

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
    }
}

nonisolated private struct StartLocalFocusSessionRPCPayload: Encodable {
    let durationMinutes: Int

    enum CodingKeys: String, CodingKey {
        case durationMinutes = "duration_minutes"
    }
}

nonisolated private struct FocusSessionRPCPayload: Encodable {
    let sessionID: UUID

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
    }
}

// MARK: - Realtime Payloads

nonisolated private struct FocusRequestRealtimeRecord: Decodable {
    let id: UUID
    let requesterID: UUID
    let approverID: UUID
    let durationMinutes: Int
    let status: FocusRequestStatus

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case approverID = "approver_id"
        case durationMinutes = "duration_minutes"
        case status
    }

    var focusRequest: FocusRequest {
        FocusRequest(
            id: id,
            requesterID: requesterID,
            approverID: approverID,
            durationMinutes: durationMinutes,
            status: status,
            createdAt: nil,
            respondedAt: nil,
            activatedAt: nil,
            endsAt: nil
        )
    }
}

nonisolated private struct FocusRequestBroadcastPayload: Decodable {
    let record: FocusRequestRealtimeRecord
}
