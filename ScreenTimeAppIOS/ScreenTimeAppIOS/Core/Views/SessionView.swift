//
//  SessionView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct SessionView: View {
    private let durations = [15, 25, 30, 45, 60, 90]
    
    private let apps = ["Instagram", "TikTok", "Twitter", "YouTube", "Spotify", "Netflix", "Snapchat"]
    
    private let friends = ["Abel", "Mia Kim", "Chloe Palmer"]

    // Defines exactly 3 flexible columns
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private let blockedAppColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ZStack{
            Color("Background").ignoresSafeArea(edges: .all)
            
                ScrollView{
                   
                    VStack {
                     
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                                .foregroundColor(Constants.secondaryTextColor)
                                .padding(.leading)
                                .imageScale(.large)
                                
                            Text("Start Focus Session")
                                .font(.title)
                                .bold()
                                .foregroundColor(Constants.primaryTextColor)
                                .padding()
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Text("Duration")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Constants.primaryTextColor)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(durations, id: \.self) { minutes in
                                    durationButton(minutes: minutes)
                                }
                            }
                

                        }
                        .padding(20) // Spacing inside the card
                        .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                        .background(Constants.backgroundSecondaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                        .padding(.horizontal) // Spacing outside the card
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What Gets Blocked")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Constants.primaryTextColor)
                            
                            Text("Social + Entertainment apps will be paused during you session.")
                                .foregroundStyle(Constants.secondaryTextColor)
                                .fontWeight(.semibold)
                            
                            VStack{
                                LazyVGrid(columns: blockedAppColumns, spacing: 5) {
                                    ForEach(apps, id: \.self) { app in
                                        BlockedAppView(app: app)
                                    }
                                }
                            }
                

                        }
                        .padding(20) // Spacing inside the card
                        .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                        .background(Constants.backgroundSecondaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                        .padding(.horizontal) // Spacing outside the card
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose a friend to notify")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Constants.primaryTextColor)
                            
                            Text("They'll get a request to start a session with you")
                                .foregroundStyle(Constants.secondaryTextColor)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(friends, id: \.self) { friend in
                                    FriendListItem(friend: friend)
                                }
                            }
                        }
                        .padding(20) // Spacing inside the card
                        .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                        .background(Constants.backgroundSecondaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                        .padding(.horizontal) // Spacing outside the card
                        
                        
                        Spacer()
                }
            }
        }
    }

    private func durationButton(minutes: Int) -> some View {
        Button {
            print("Selected \(minutes) minutes")
        } label: {
            Text("\(minutes) min")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Constants.secondaryTextColor)
                .foregroundColor(Constants.buttonForeColor)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }
    
    private func BlockedAppView(app: String) -> some View {
        
        Text(app)
            .font(.body)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: 90, height: 25)
            .background(Constants.secondaryTextColor)
            .foregroundColor(Constants.buttonForeColor)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    
    private func FriendListItem(friend: String) -> some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundStyle(Constants.primaryTextColor)
            
            VStack {
                Text(friend)
            }
        }
    }
    
}

#Preview {
    SessionView()
}
