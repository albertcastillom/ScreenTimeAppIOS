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
    /// The selection belongs to this device. Focus requests only carry a duration;
    /// selected apps are never uploaded or shared with the approving friend.
    var activitySelection = FamilyActivitySelection() {
        didSet {
            stateStore.saveActivitySelection(activitySelection)
        }
    }
    var isBlocking = false
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

    func updateActivitySelection(_ selection: FamilyActivitySelection) {
        activitySelection = selection
    }

    @discardableResult
    func startFocusSession(durationMinutes: Int) -> Bool {
        // Do not let a second request replace the one shared schedule/store. It can
        // remain accepted in Supabase and be retried after this session finishes.
        guard !isBlocking, hasSelectedActivities else {
            return false
        }

        guard restrictionsService.startBlocking(
            selection: activitySelection,
            durationMinutes: durationMinutes
        ) else {
            return false
        }

        let endDate = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        updateBlockingState(isBlocking: true, sessionEndDate: endDate)
        return true
    }

    func stopFocusSession() {
        restrictionsService.stopBlocking()
        updateBlockingState(isBlocking: false, sessionEndDate: nil)
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

    private func updateBlockingState(isBlocking: Bool, sessionEndDate: Date?) {
        self.isBlocking = isBlocking
        self.sessionEndDate = sessionEndDate
        stateStore.saveBlockingState(isBlocking: isBlocking, sessionEndDate: sessionEndDate)
    }

    private var hasSelectedActivities: Bool {
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty ||
        !activitySelection.webDomainTokens.isEmpty
    }
}
