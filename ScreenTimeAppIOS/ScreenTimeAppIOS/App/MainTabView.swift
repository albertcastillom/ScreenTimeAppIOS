//
//  MainTabView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/25/26.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var focusRequestCoordinator = FocusRequestCoordinator()

    var body: some View {
        TabView {
            Tab(Constants.homeString, systemImage: Constants.homeIconString) {
                NavigationStack {
                    HomeView()
                }
            }
            Tab(Constants.friendsString, systemImage: Constants.friendsIconString) {
                NavigationStack {
                    FriendsView()
                }
            }
            Tab(Constants.leaderboardString, systemImage: Constants.leaderboardIconString) {
                NavigationStack {
                    LeaderboardView()
                }
            }
        }
        .tint(Constants.primaryTextColor)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .task {
            // One coordinator owns both the Realtime listener and the blocking
            // model shared by every tab through the environment.
            focusRequestCoordinator.start()
        }
        .environment(focusRequestCoordinator.appBlockingModel)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            // Reconcile immediately after foregrounding; Realtime sockets can be
            // suspended while the app is in the background.
            focusRequestCoordinator.appBlockingModel.refreshBlockingState()
            focusRequestCoordinator.start()
            Task {
                await focusRequestCoordinator.reconcileAcceptedRequests()
            }
        }
        .onDisappear {
            focusRequestCoordinator.stop()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
