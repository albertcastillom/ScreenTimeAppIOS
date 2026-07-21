//
//  ContentView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
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

#Preview {
    ContentView()
}
