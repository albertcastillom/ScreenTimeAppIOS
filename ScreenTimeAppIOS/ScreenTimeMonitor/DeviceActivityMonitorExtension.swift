//
//  DeviceActivityMonitorExtension.swift
//  ScreenTimeMonitor
//
//  Created by Albert Castillo on 7/30/26.
//

import DeviceActivity
import Foundation
import ManagedSettings

// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: ScreenTimeIdentifiers.managedSettingsStoreName)
    private let stateStore = BlockingStateStore()
   
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        guard activity == ScreenTimeIdentifiers.deviceActivityName else {
            return
        }

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        stateStore.clearBlockingState()
    }
}
