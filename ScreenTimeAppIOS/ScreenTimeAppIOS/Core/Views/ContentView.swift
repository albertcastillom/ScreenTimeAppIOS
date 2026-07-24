//
//  ContentView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(AuthManager.self) private var authManager
    
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
