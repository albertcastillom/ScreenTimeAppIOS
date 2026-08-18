//
//  FocusSessionCoordinator.swift
//  ScreenTimeAppIOS
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class FocusSessionCoordinator {
    let appBlockingModel: AppBlockingModel

    private(set) var errorMessage: String?

    @ObservationIgnored private let service: SupabaseService
    @ObservationIgnored private var listenerTask: Task<Void, Never>?
    @ObservationIgnored private var handledRequestIDs: Set<UUID> = []
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ScreenTimeAppIOS",
        category: "FocusSessionCoordinator"
    )

    private static let initialRetryDelayNanoseconds: UInt64 = 1_000_000_000
    private static let maximumRetryDelayNanoseconds: UInt64 = 30_000_000_000

    init() {
        self.service = SupabaseService()
        self.appBlockingModel = AppBlockingModel()
    }

    init(service: SupabaseService, appBlockingModel: AppBlockingModel) {
        self.service = service
        self.appBlockingModel = appBlockingModel
    }

    func start() {
        guard listenerTask == nil else {
            return
        }

        errorMessage = nil
        listenerTask = Task { [weak self] in
            guard let self else {
                return
            }
            await listenForAcceptedRequests()
        }
    }

    func stop() {
        listenerTask?.cancel()
        listenerTask = nil
    }

    /// Reconciles database state whenever the app returns to the foreground. This
    /// is the durable fallback for an acceptance that arrived while iOS suspended
    /// the process or while the Realtime socket was reconnecting.
    func reconcileAcceptedRequests() async {
        do {
            try await activateAcceptedRequestsFromDatabase()
        } catch is CancellationError {
            // Foreground work may be cancelled as the scene changes again.
        } catch {
            logger.error("Accepted-request reconciliation failed: \(String(describing: error), privacy: .public)")
            errorMessage = "Could not check for accepted focus requests."
        }
    }

    private func listenForAcceptedRequests() async {
        var retryDelay = Self.initialRetryDelayNanoseconds

        while !Task.isCancelled {
            do {
                // Create the stream first so updates are buffered while the catch-up
                // query finds acceptances that happened while the app was offline.
                let updates = try await service.acceptedFocusRequestUpdates()
                try await activateAcceptedRequestsFromDatabase()
                logger.info("Focus-request Realtime listener subscribed")
                errorMessage = nil
                retryDelay = Self.initialRetryDelayNanoseconds

                for try await request in updates {
                    try Task.checkCancellation()
                    logger.info("Received accepted focus request \(request.id.uuidString, privacy: .public)")
                    await activate(request)
                }

                // A non-cancelled stream should remain open. If it closes, reconnect.
                guard !Task.isCancelled else {
                    return
                }
                logger.warning("Focus-request Realtime stream ended; reconnecting")
            } catch is CancellationError {
                return
            } catch {
                logger.error("Focus-request Realtime listener failed: \(String(describing: error), privacy: .public)")
                errorMessage = "Realtime disconnected. Reconnecting…"
            }

            do {
                try await Task.sleep(nanoseconds: retryDelay)
            } catch {
                return
            }
            retryDelay = min(retryDelay * 2, Self.maximumRetryDelayNanoseconds)
        }
    }

    private func activateAcceptedRequestsFromDatabase() async throws {
        let acceptedRequests = try await service.getAcceptedOutgoingFocusRequests()
        logger.info("Found \(acceptedRequests.count, privacy: .public) accepted request(s) during reconciliation")

        for request in acceptedRequests {
            await activate(request)
        }
    }

    private func activate(_ request: FocusRequest) async {
        guard request.status == .accepted,
              handledRequestIDs.insert(request.id).inserted else {
            return
        }

        appBlockingModel.selectDuration(minutes: request.durationMinutes)

        guard appBlockingModel.startFocusSession() else {
            logger.error("Blocking failed for accepted request \(request.id.uuidString, privacy: .public)")
            handledRequestIDs.remove(request.id)
            errorMessage = "A focus request was accepted, but app blocking could not start."
            return
        }

        logger.info("Blocking started for request \(request.id.uuidString, privacy: .public)")

        do {
            _ = try await service.activateFocusRequest(id: request.id)
            logger.info("Marked request \(request.id.uuidString, privacy: .public) activated")
            errorMessage = nil
        } catch {
            // Restrictions are already active locally. Keep this request handled so
            // a duplicate realtime event cannot restart the same session.
            logger.error("Could not mark request activated: \(String(describing: error), privacy: .public)")
            errorMessage = "App blocking started, but the focus request could not be marked active."
        }
    }
}
