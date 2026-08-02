//
//  BlockingStateStore.swift
//  ScreenTimeAppIOS
//

import FamilyControls
import Foundation

struct BlockingSessionState {
    let isBlocking: Bool
    let sessionEndDate: Date?
}

final class BlockingStateStore {
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: ScreenTimeIdentifiers.appGroupIdentifier)) {
        self.defaults = defaults
    }

    func loadBlockingState(now: Date = Date()) -> BlockingSessionState {
        guard let defaults else {
            return BlockingSessionState(isBlocking: false, sessionEndDate: nil)
        }

        let sessionEndDate = defaults.object(forKey: ScreenTimeIdentifiers.sessionEndDateKey) as? Date
        let isBlocking = defaults.bool(forKey: ScreenTimeIdentifiers.isBlockingKey)

        if let sessionEndDate, sessionEndDate <= now {
            saveBlockingState(isBlocking: false, sessionEndDate: nil)
            return BlockingSessionState(isBlocking: false, sessionEndDate: nil)
        }

        return BlockingSessionState(isBlocking: isBlocking, sessionEndDate: sessionEndDate)
    }

    func saveBlockingState(isBlocking: Bool, sessionEndDate: Date?) {
        defaults?.set(isBlocking, forKey: ScreenTimeIdentifiers.isBlockingKey)

        if let sessionEndDate {
            defaults?.set(sessionEndDate, forKey: ScreenTimeIdentifiers.sessionEndDateKey)
        } else {
            defaults?.removeObject(forKey: ScreenTimeIdentifiers.sessionEndDateKey)
        }
    }

    func clearBlockingState() {
        saveBlockingState(isBlocking: false, sessionEndDate: nil)
    }

    func loadActivitySelection() -> FamilyActivitySelection {
        guard let data = defaults?.data(forKey: ScreenTimeIdentifiers.activitySelectionKey) else {
            return FamilyActivitySelection()
        }

        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to load saved activity selection: \(error)")
            defaults?.removeObject(forKey: ScreenTimeIdentifiers.activitySelectionKey)
            return FamilyActivitySelection()
        }
    }

    func saveActivitySelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            defaults?.set(data, forKey: ScreenTimeIdentifiers.activitySelectionKey)
        } catch {
            print("Failed to save activity selection: \(error)")
        }
    }
}
