//
//  AppBlockingModule.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/30/26.
//

import Foundation
import Observation
import FamilyControls

enum ActiveFocusSessionSource: String {
    case local
    case focusRequest
}

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
    private(set) var activeSessionSource: ActiveFocusSessionSource?
    var sessionEndDate: Date?
    private(set) var focusSessionID: UUID?
    private(set) var errorMessage: String?

    @ObservationIgnored private let restrictionsService: RestrictionsService
    @ObservationIgnored private let stateStore: BlockingStateStore
    @ObservationIgnored private let service: SupabaseService

    init() {
        self.restrictionsService = RestrictionsService()
        self.stateStore = BlockingStateStore()
        self.service = SupabaseService()
        activitySelection = stateStore.loadActivitySelection()
        refreshBlockingState()
    }

    init(
        restrictionsService: RestrictionsService,
        stateStore: BlockingStateStore,
        service: SupabaseService? = nil
    ) {
        self.restrictionsService = restrictionsService
        self.stateStore = stateStore
        self.service = service ?? SupabaseService()
        activitySelection = stateStore.loadActivitySelection()
        refreshBlockingState()
    }

    func updateActivitySelection(_ selection: FamilyActivitySelection) {
        activitySelection = selection
    }

    @discardableResult
    func startFocusSession(durationMinutes: Int, source: ActiveFocusSessionSource) -> Bool {
        // Do not let a second request replace the one shared schedule/store. It can
        // remain accepted in Supabase and be retried after this session finishes.
        guard !isBlocking, focusSessionID == nil, hasSelectedActivities else {
            return false
        }

        guard restrictionsService.startBlocking(
            selection: activitySelection,
            durationMinutes: durationMinutes
        ) else {
            return false
        }

        let endDate = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        activeSessionSource = source
        stateStore.saveActiveSessionSource(source)
        updateBlockingState(isBlocking: true, sessionEndDate: endDate)
        return true
    }

    @discardableResult
    func startLocalFocusSession(durationMinutes: Int) async -> Bool {
        errorMessage = nil

        guard startFocusSession(durationMinutes: durationMinutes, source: .local) else {
            if isBlocking {
                errorMessage = "A focus session is already active."
            } else if focusSessionID != nil {
                errorMessage = "The previous focus session is still syncing."
            } else {
                errorMessage = "Choose at least one app, category, or website to block."
            }
            return false
        }

        do {
            let session = try await service.startLocalFocusSession(
                durationMinutes: durationMinutes
            )
            focusSessionID = session.id
            stateStore.saveFocusSessionID(session.id)
            scheduleNaturalCompletion(at: session.scheduledEndsAt)
            return true
        } catch {
            restrictionsService.stopBlocking()
            clearBlockingStateAndSessionID()
            errorMessage = "Could not save the focus session. App blocking was stopped."
            return false
        }
    }

    @discardableResult
    func endFocusSessionEarly() async -> Bool {
        errorMessage = nil

        guard let focusSessionID else {
            restrictionsService.stopBlocking()
            clearBlockingStateAndSessionID()
            return true
        }

        do {
            _ = try await service.endFocusSessionEarly(id: focusSessionID)
            restrictionsService.stopBlocking()
            clearBlockingStateAndSessionID()
            return true
        } catch {
            errorMessage = "Could not end the focus session. App blocking is still active."
            return false
        }
    }

    func reconcileElapsedFocusSession() async {
        refreshBlockingState()

        do {
            _ = try await service.reconcileElapsedFocusSessions()
            errorMessage = nil
        } catch {
            errorMessage = "Could not reconcile elapsed focus sessions."
        }

        guard let focusSessionID else {
            return
        }

        do {
            let session = try await service.reconcileElapsedFocusSession(id: focusSessionID)
            errorMessage = nil
            guard session.status != .active else {
                return
            }

            restrictionsService.stopBlocking()
            clearBlockingStateAndSessionID()
        } catch {
            errorMessage = "Could not reconcile the last focus session."
        }
    }

    func scheduleNaturalCompletion(at endDate: Date) {
        sessionEndDate = endDate
        stateStore.saveBlockingState(isBlocking: true, sessionEndDate: endDate)

        let delayNanoseconds = UInt64(max(0, endDate.timeIntervalSinceNow) * 1_000_000_000)
        Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            } catch {
                return
            }

            await self?.reconcileElapsedFocusSession()
        }
    }

    func refreshBlockingState() {
        let blockingState = stateStore.loadBlockingState()
        isBlocking = blockingState.isBlocking
        sessionEndDate = blockingState.sessionEndDate
        focusSessionID = blockingState.focusSessionID
        activeSessionSource = stateStore.loadActiveSessionSource()
        stateStore.saveActiveSessionSource(nil)
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

    private func clearBlockingStateAndSessionID() {
        focusSessionID = nil
        activeSessionSource = nil
        
        stateStore.saveFocusSessionID(nil)
        stateStore.saveActiveSessionSource(nil)
        updateBlockingState(isBlocking: false, sessionEndDate: nil)
    }

    private var hasSelectedActivities: Bool {
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty ||
        !activitySelection.webDomainTokens.isEmpty
    }
}
