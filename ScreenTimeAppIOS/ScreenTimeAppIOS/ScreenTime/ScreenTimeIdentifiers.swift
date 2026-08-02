//
//  ScreenTimeIdentifiers.swift
//  ScreenTimeAppIOS
//

import DeviceActivity
import Foundation
import ManagedSettings

enum ScreenTimeIdentifiers {
    static let appGroupIdentifier = "group.com.albertcastillo.ScreenTimeAppIOS"
    static let managedSettingsStoreName = ManagedSettingsStore.Name("ScreenTimeAppIOS")
    static let deviceActivityName = DeviceActivityName("focus Session")

    static let isBlockingKey = "isBlocking"
    static let sessionEndDateKey = "sessionEndDate"
    static let activitySelectionKey = "activitySelection"
}
