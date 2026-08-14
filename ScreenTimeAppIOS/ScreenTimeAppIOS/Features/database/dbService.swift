//
//  dbService.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 8/3/26.
//

import Foundation
import Supabase

// MARK: - Profile Models

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case createdAt = "created_at"
    }
}

// MARK: - Friendship Models

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
    case blocked
}

struct Friendship: Codable, Identifiable, Equatable {
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

enum FocusRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
    case activated
    case cancelled
    case expired
    case failed
}

struct FocusRequest: Codable, Identifiable, Equatable {
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

// MARK: - Supabase Service

struct SupabaseService {
    private let client: SupabaseClient

    init() {
        guard let projectURL = URL(string: AppConstants.projectURLString) else {
            preconditionFailure("Invalid Supabase project URL")
        }

        self.client = SupabaseClient(
            supabaseURL: projectURL,
            supabaseKey: AppConstants.projectAPIKey
        )
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

    func getFriendships(for userID: UUID? = nil) async throws -> [Friendship] {
        let userID = try await resolvedUserID(userID)

        return try await client
            .from("friendships")
            .select()
            .or("requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString)")
            .execute()
            .value
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

    // MARK: Focus Requests - Realtime

    func acceptedFocusRequestUpdates() async throws -> AsyncStream<FocusRequest> {
        let requesterID = try await currentUserID()
        let channel = client.realtimeV2.channel("focus-requests-\(requesterID.uuidString)")
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "focus_requests",
            filter: .eq("requester_id", value: requesterID)
        )

        return AsyncStream { continuation in
            let task = Task {
                do {
                    try await channel.subscribeWithError()

                    for await update in updates {
                        guard let request = decodeAcceptedFocusRequest(from: update) else {
                            continue
                        }
                        continuation.yield(request)
                    }
                } catch {
                    continuation.finish()
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
                Task {
                    await channel.unsubscribe()
                }
            }
        }
    }

    private func decodeAcceptedFocusRequest(from update: UpdateAction) -> FocusRequest? {
        guard let record = try? update.decodeRecord(
            as: FocusRequestRealtimeRecord.self,
            decoder: JSONDecoder()
        ), record.status == .accepted else {
            return nil
        }

        return record.focusRequest
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

private struct ProfileUpdatePayload: Encodable {
    let username: String?

    enum CodingKeys: String, CodingKey {
        case username
    }
}

private struct FriendshipInsertPayload: Encodable {
    let requesterID: UUID
    let addresseeID: UUID
    let status: FriendshipStatus

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
        case addresseeID = "addressee_id"
        case status
    }
}

private struct FriendshipStatusUpdatePayload: Encodable {
    let status: FriendshipStatus

    enum CodingKeys: String, CodingKey {
        case status
    }
}

private struct FocusRequestInsertPayload: Encodable {
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

private struct FocusRequestRPCPayload: Encodable {
    let requestID: UUID

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
    }
}

// MARK: - Realtime Payloads

private struct FocusRequestRealtimeRecord: Decodable {
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
