//
//  DeviceActivityMonitorExtension.swift
//  ScreenTimeMonitor
//
//  Created by Albert Castillo on 7/30/26.
//

import DeviceActivity
import Foundation
import ManagedSettings

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private enum SharedState {
        static let appGroupIdentifier = "group.com.albertcastillo.ScreenTimeAppIOS"
        static let isBlockingKey = "isBlocking"
        static let sessionEndDateKey = "sessionEndDate"
    }
    
    private let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("ScreenTimeAppIOS")
    )
    private let sharedDefaults = UserDefaults(suiteName: SharedState.appGroupIdentifier)
   
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Handle the start of the interval.
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Handle the end of the interval.
        
        guard activity == DeviceActivityName("focus Session") else {
            return
        }

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        sharedDefaults?.set(false, forKey: SharedState.isBlockingKey)
        sharedDefaults?.removeObject(forKey: SharedState.sessionEndDateKey)
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle the event reaching its threshold.
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        // Handle the warning before the event reaches its threshold.
    }
}
