//
//  InviteRouter.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 11/14/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class InviteRouter {
    private(set) var pendingInviterID: UUID?

    private let userDefaults: UserDefaults

    private static let customURLScheme = "com.albertcastillo.commit"
    private static let customInviteHost = "invite"
    private static let pendingInviterIDKey = "pendingFriendInviteInviterID"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let storedID = userDefaults.string(forKey: Self.pendingInviterIDKey) {
            pendingInviterID = UUID(uuidString: storedID)
        }
    }

   // Routes friend invite url and stores id of invtiter
    //Returns true when the URL is a valid friend invite. Invalid URLs
    // do not replace an invite that is already waiting to be handled.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard let inviterID = inviterID(from: url) else {
            return false
        }

        pendingInviterID = inviterID
        userDefaults.set(inviterID.uuidString, forKey: Self.pendingInviterIDKey)
        return true
    }

    // Clears the pending invite after it is completed or dismissed
    func clearPendingInvite() {
        pendingInviterID = nil
        userDefaults.removeObject(forKey: Self.pendingInviterIDKey)
    }

    private func inviterID(from url: URL) -> UUID? {
        let scheme = url.scheme?.lowercased()

        if scheme == "https" {
            return inviterID(fromUniversalLink: url)
        }

        if scheme == Self.customURLScheme {
            return inviterID(fromCustomURL: url)
        }

        return nil
    }

    private func inviterID(fromUniversalLink url: URL) -> UUID? {
        guard
            url.host?.lowercased() == AppConstants.inviteBaseURL.host?.lowercased(),
            url.port == nil
        else {
            return nil
        }

        let pathComponents = invitePathComponents(from: url)
        guard pathComponents.count == 2, pathComponents[0] == "invite" else {
            return nil
        }

        return UUID(uuidString: pathComponents[1])
    }

    private func inviterID(fromCustomURL url: URL) -> UUID? {
        guard url.host?.lowercased() == Self.customInviteHost else {
            return nil
        }

        let pathComponents = invitePathComponents(from: url)
        guard pathComponents.count == 1 else {
            return nil
        }

        return UUID(uuidString: pathComponents[0])
    }

    private func invitePathComponents(from url: URL) -> [String] {
        url.path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
    }
}
