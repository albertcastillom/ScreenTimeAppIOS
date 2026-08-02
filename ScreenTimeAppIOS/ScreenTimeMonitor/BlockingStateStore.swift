//
//  BlockingStateStore.swift
//  ScreenTimeMonitor
//

import Foundation

final class BlockingStateStore {
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: ScreenTimeIdentifiers.appGroupIdentifier)) {
        self.defaults = defaults
    }

    func clearBlockingState() {
        defaults?.set(false, forKey: ScreenTimeIdentifiers.isBlockingKey)
        defaults?.removeObject(forKey: ScreenTimeIdentifiers.sessionEndDateKey)
    }
}
