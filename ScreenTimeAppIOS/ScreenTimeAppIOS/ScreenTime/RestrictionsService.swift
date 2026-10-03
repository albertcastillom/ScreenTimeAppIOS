//
//  AppBlockerUtil.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/30/26.
//

import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

final class RestrictionsService {
    private let store = ManagedSettingsStore(named: ScreenTimeIdentifiers.managedSettingsStoreName)
    private let center = DeviceActivityCenter()
    
    /// Applies shields immediately. The monitor extension is responsible only for
    /// removing them when the scheduled interval ends.
    private func applyRestrictions(selection: FamilyActivitySelection) {
        let applicationTokens = selection.applicationTokens
        let categoryTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens
        
        store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens
        store.shield.applicationCategories = categoryTokens.isEmpty ? nil : .specific(categoryTokens)
        store.shield.webDomains = webTokens.isEmpty ? nil : webTokens
    }
    
    private func removeRestrictions() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    @discardableResult
    private func startMonitoringSchedule(durationInMinutes: Int) -> Bool {
        // Apple's DeviceActivity schedules require at least a 15-minute interval.
        guard durationInMinutes >= 15 else {
            print("Error: The minimum schedule interval allowed by Apple is 15 minutes.")
            return false
        }
          
        let calendar = Calendar.current
        let startDate = Date()
          
        guard let endDate = calendar.date(byAdding: .minute, value: durationInMinutes, to: startDate) else {
            return false
        }
          
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let intervalStart = calendar.dateComponents(components, from: startDate)
        let intervalEnd = calendar.dateComponents(components, from: endDate)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: false,
            warningTime: nil
        )
          
        do {
            try center.startMonitoring(ScreenTimeIdentifiers.deviceActivityName, during: schedule)
            return true
        } catch {
            print("Error starting DeviceActivity monitoring: \(error)")
            return false
        }
    }
    
    private func stopMonitoring() {
        center.stopMonitoring([ScreenTimeIdentifiers.deviceActivityName])
    }
    
    @discardableResult
    func startBlocking(selection: FamilyActivitySelection, durationMinutes: Int) -> Bool {
        applyRestrictions(selection: selection)

        guard startMonitoringSchedule(durationInMinutes: durationMinutes) else {
            removeRestrictions()
            return false
        }

        return true
    }
    
    func stopBlocking() {
        removeRestrictions()
        stopMonitoring()
    }
}
