//
//  ContentView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    
    @Environment(AuthManager.self) private var authManager
    @StateObject var ScreenTimeManager = AuthorizationManager()
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .notDetermined:
                VStack {
                    Text("ScreenTime App")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    ProgressView()
                }
            case .notAuthenticated:
                NavigationStack {
                    SignUpView()
                }
            case .authenticated:
                VStack{
                    if ScreenTimeManager.authorizationStatus == .notDetermined {
                        Button("Request Authorization") {
                            Task {
                                await ScreenTimeManager.requestAuthorization()
                            }
                        }
                    } else if ScreenTimeManager.authorizationStatus == .approved {
                        TabView {
                            Tab(Constants.homeString, systemImage: Constants.homeIconString){
                                NavigationStack {
                                    HomeView()
                                }
                            }
                            Tab(Constants.friendsString, systemImage: Constants.friendsIconString){
                                NavigationStack{
                                    FriendsView()
                                }
                            }
                            Tab(Constants.leaderboardString, systemImage: Constants.leaderboardIconString){
                                NavigationStack{
                                    LeaderboardView()
                                }
                            }
                        }
                        .tint(Constants.primaryTextColor)
                        .toolbarBackground(.visible, for: .tabBar)
                        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                    } else {
                        Text("Authorization Denied or Restricted. Please enable in Settings.")
                        // Guide user to Settings if needed
                    }
                }
                .onAppear {
                    Task {
                        await ScreenTimeManager.checkAuthorization()
                    }
                }
            }
        }
        .task {
            await authManager.getAuthState()
        }
        
    }
}

#Preview {
    ContentView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
