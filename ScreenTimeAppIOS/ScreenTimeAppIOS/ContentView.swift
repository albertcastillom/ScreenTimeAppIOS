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
               HomeView()
            }
            Tab(Constants.friendsString, systemImage: Constants.friendsIconString){
                Text(Constants.friendsString)
            }
            Tab(Constants.leaderboardString, systemImage: Constants.leaderboardIconString){
                Text(Constants.leaderboardString)
            }
        }
    }
}

#Preview {
    ContentView()
}
