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

class RestrictionsService {
    
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("ScreenTimeAppIOS"))
    let center = DeviceActivityCenter()
    
    func applyRestrictions(selection: FamilyActivitySelection){
        
        //extract tokens from selection
        let applicationTokens = selection.applicationTokens
        let categoryTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens
        
        //apply tokens to shield
        store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens
        store.shield.applicationCategories = categoryTokens.isEmpty ? nil : .specific(categoryTokens)
        store.shield.webDomains = webTokens.isEmpty ? nil : webTokens
    }
    
    func removeRestrictions(){
       
        // Clear the shield configuration
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    // Define a unique name for your activity
static let activityName = DeviceActivityName("focus Session")
      
    @discardableResult
    func startMonitoringSchedule(durationInMinutes: Int) -> Bool {
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
            try center.startMonitoring(Self.activityName, during: schedule)
            return true
        } catch {
            print("Error starting DeviceActivity monitoring: \(error)")
            return false
        }
    }
    
       func stopMonitoring() {
           // Stop monitoring for all activities or specify names
           center.stopMonitoring([Self.activityName])
       }
    
    // Combined Activation Logic (Similar to provided code)
    @discardableResult
    func activateRestrictions(selection: FamilyActivitySelection, minutes: Int) -> Bool {
        applyRestrictions(selection: selection)

        guard startMonitoringSchedule(durationInMinutes: minutes) else {
            removeRestrictions()
            return false
        }

        return true
    }
    
    // Combined Deactivation Logic
    func deactivateRestrictions() {
        removeRestrictions()
        stopMonitoring()
    }
}
