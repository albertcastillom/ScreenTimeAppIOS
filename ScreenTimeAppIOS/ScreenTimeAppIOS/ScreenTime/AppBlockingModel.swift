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
    var activitySelection = FamilyActivitySelection() {
        didSet {
            stateStore.saveActivitySelection(activitySelection)
        }
    }
    var isPickerPresented = false
    var isBlocking = false
    var selectedDurationMinutes: Int?
    var selectedFriend: String?
    var sessionEndDate: Date?

    @ObservationIgnored private let restrictionsService: RestrictionsService
    @ObservationIgnored private let stateStore: BlockingStateStore

    init() {
        self.restrictionsService = RestrictionsService()
        self.stateStore = BlockingStateStore()
        activitySelection = stateStore.loadActivitySelection()
        refreshBlockingState()
    }

    init(restrictionsService: RestrictionsService, stateStore: BlockingStateStore) {
        self.restrictionsService = restrictionsService
        self.stateStore = stateStore
        activitySelection = stateStore.loadActivitySelection()
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
        let blockingState = stateStore.loadBlockingState()
        isBlocking = blockingState.isBlocking
        sessionEndDate = blockingState.sessionEndDate
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

    private func saveBlockingState(isBlocking: Bool, sessionEndDate: Date?) {
        self.isBlocking = isBlocking
        self.sessionEndDate = sessionEndDate
        stateStore.saveBlockingState(isBlocking: isBlocking, sessionEndDate: sessionEndDate)
    }

    private var hasSelectedApps: Bool {
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty ||
        !activitySelection.webDomainTokens.isEmpty
    }
}
