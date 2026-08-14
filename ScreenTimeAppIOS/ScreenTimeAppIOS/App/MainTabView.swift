//
//  MainTabView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/25/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var appBlockingModel = AppBlockingModel()
    @State private var focusSessionViewModel = FocusSessionViewModel()

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
            focusSessionViewModel.startListeningForAcceptedFocusRequests { request in
                await handleAcceptedFocusRequest(request)
            }

            for request in await focusSessionViewModel.loadAcceptedOutgoingFocusRequests() {
                await handleAcceptedFocusRequest(request)
            }
        }
        .environment(appBlockingModel)
        .onDisappear {
            focusSessionViewModel.stopListeningForAcceptedFocusRequests()
        }
    }

    @MainActor
    private func handleAcceptedFocusRequest(_ request: FocusRequest) async {
        appBlockingModel.selectDuration(minutes: request.durationMinutes)

        if appBlockingModel.startFocusSession() {
            await focusSessionViewModel.markFocusSessionActivated(request)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
