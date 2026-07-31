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
       static let activityName = DeviceActivityName("com.screentime.screentimeapp.blockerActivity")
      
       func startMonitoringSchedule() {
           // Define a schedule. This example is 24/7, repeating daily.
           let schedule = DeviceActivitySchedule(
               intervalStart: DateComponents(hour: 17, minute: 0),
               intervalEnd: DateComponents(hour: 18, minute: 0),
               repeats: true,
               warningTime: nil // No warning needed for simple blocking
           )
          
           do {
               // Start monitoring. This tells the system to check the 'store'
               // associated with this activity during the 'schedule'.
               try center.startMonitoring(Self.activityName, during: schedule)
           } catch {
               print("Error starting DeviceActivity monitoring: \(error)")
           }
       }
       func stopMonitoring() {
           // Stop monitoring for all activities or specify names
           center.stopMonitoring([Self.activityName])
          
       }
       // Combined Activation Logic (Similar to provided code)
       func activateRestrictions(selection: FamilyActivitySelection) {
           applyRestrictions(selection: selection) // Step 2: Define rules
          // startMonitoringSchedule()             // Step 3: Activate schedule
       }
       // Combined Deactivation Logic
       func deactivateRestrictions() {
           removeRestrictions() // Step 2: Clear rules
          // stopMonitoring()     // Step 3: Deactivate schedule
       }
}
