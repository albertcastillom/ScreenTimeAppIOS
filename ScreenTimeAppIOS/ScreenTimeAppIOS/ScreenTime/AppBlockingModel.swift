//
//  AppBlockingModule.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/30/26.
//

import Foundation
import Observation
import FamilyControls

@Observable
@MainActor
final class AppBlockingModel {
    private enum SharedState {
        static let appGroupIdentifier = "group.com.albertcastillo.ScreenTimeAppIOS"
        static let isBlockingKey = "isBlocking"
        static let sessionEndDateKey = "sessionEndDate"
        static let activitySelectionKey = "activitySelection"
    }

    var activitySelection = FamilyActivitySelection() {
        didSet {
            saveActivitySelection()
        }
    }
    var isPickerPresented = false
    var isBlocking = false
    var selectedDurationMinutes: Int?
    var selectedFriend: String?
    var sessionEndDate: Date?

    @ObservationIgnored private let restrictionsService = RestrictionsService()
    @ObservationIgnored private let sharedDefaults = UserDefaults(suiteName: SharedState.appGroupIdentifier)

    init() {
        loadActivitySelection()
        refreshBlockingState()
    }

    func presentAppPicker() {
        isPickerPresented = true
    }

    func selectDuration(minutes: Int) {
        selectedDurationMinutes = minutes
    }

    func selectFriend(_ friend: String) {
        selectedFriend = friend
    }

    func startFocusSession() {
        guard hasSelectedApps else {
            print("No apps, categories, or websites selected.")
            return
        }

        guard let selectedDurationMinutes else {
            print("No duration selected.")
            return
        }

        guard selectedFriend != nil else {
            print("No friend selected.")
            return
        }

        guard restrictionsService.activateRestrictions(selection: activitySelection, minutes: selectedDurationMinutes) else {
            return
        }

        let endDate = Date().addingTimeInterval(TimeInterval(selectedDurationMinutes * 60))
        saveBlockingState(isBlocking: true, sessionEndDate: endDate)
    }

    func stopFocusSession() {
        restrictionsService.deactivateRestrictions()
        saveBlockingState(isBlocking: false, sessionEndDate: nil)
    }

    func toggleFocusSession() {
        if isBlocking {
            stopFocusSession()
        } else {
            startFocusSession()
        }
    }

    func refreshBlockingState() {
        guard let sharedDefaults else {
            isBlocking = false
            sessionEndDate = nil
            return
        }

        let savedEndDate = sharedDefaults.object(forKey: SharedState.sessionEndDateKey) as? Date
        let savedIsBlocking = sharedDefaults.bool(forKey: SharedState.isBlockingKey)

        if let savedEndDate, savedEndDate <= Date() {
            saveBlockingState(isBlocking: false, sessionEndDate: nil)
        } else {
            isBlocking = savedIsBlocking
            sessionEndDate = savedEndDate
        }
    }

    private func saveBlockingState(isBlocking: Bool, sessionEndDate: Date?) {
        self.isBlocking = isBlocking
        self.sessionEndDate = sessionEndDate

        sharedDefaults?.set(isBlocking, forKey: SharedState.isBlockingKey)

        if let sessionEndDate {
            sharedDefaults?.set(sessionEndDate, forKey: SharedState.sessionEndDateKey)
        } else {
            sharedDefaults?.removeObject(forKey: SharedState.sessionEndDateKey)
        }
    }

    private func loadActivitySelection() {
        guard let data = sharedDefaults?.data(forKey: SharedState.activitySelectionKey) else {
            return
        }

        do {
            activitySelection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to load saved activity selection: \(error)")
            sharedDefaults?.removeObject(forKey: SharedState.activitySelectionKey)
        }
    }

    private func saveActivitySelection() {
        do {
            let data = try JSONEncoder().encode(activitySelection)
            sharedDefaults?.set(data, forKey: SharedState.activitySelectionKey)
        } catch {
            print("Failed to save activity selection: \(error)")
        }
    }
    

    var blockedSelectionSummary: [String] {
        var summary: [String] = []

        if !activitySelection.applicationTokens.isEmpty {
            summary.append("\(activitySelection.applicationTokens.count) apps")
        }

        if !activitySelection.categoryTokens.isEmpty {
            summary.append("\(activitySelection.categoryTokens.count) categories")
        }

        if !activitySelection.webDomainTokens.isEmpty {
            summary.append("\(activitySelection.webDomainTokens.count) websites")
        }

        return summary
    }

    private var hasSelectedApps: Bool {
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty ||
        !activitySelection.webDomainTokens.isEmpty
    }
}
