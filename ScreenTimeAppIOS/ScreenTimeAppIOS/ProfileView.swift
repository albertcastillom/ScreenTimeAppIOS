//
//  ProfileView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea(edges: .all)
            
            VStack {
                HStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.primaryTextColor)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                
                VStack(alignment: .leading, spacing: 12) {
     
                    HStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(Constants.primaryTextColor)
                        
                    
                            VStack(alignment: .leading, spacing: 4) {
                            Text("John Doe")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(Constants.secondaryTextColor)
                            
                            Text("johndoes@gmail.com")
                                .font(.body)
                                .foregroundStyle(Constants.secondaryTextColor)
                                
                            Text("Member since 2026")
                                .font(.body)
                                .foregroundStyle(Constants.secondaryTextColor)
                            }
                        Spacer()
                            
                        Button("Edit") {
                            print("edit Profile")
                        }
                        .padding()
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        
                    }
                }
                .padding(20) // Spacing inside the card
                .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                .background(Constants.backgroundSecondaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                .padding(.horizontal)
           
                HStack(spacing: 12) {
                    statCard(value: "20", title: "Sessions")
                    statCard(value: "3d", title: "Streak")
                    statCard(value: "5", title: "Friends")
                    statCard(value: "#4", title: "Rank")
                }
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 12) {
                    // Card Title
                    Text("Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(Constants.primaryTextColor))
                    HStack {
                        Text("Push Notifications")
                            .foregroundStyle(Constants.secondaryTextColor)
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                    }
                    HStack {
                        Text("Friend Requests")
                            .foregroundStyle(Constants.secondaryTextColor)
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                .padding(20) // Spacing inside the card
                .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                .padding(.horizontal) // Spacing outside the card
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Policy")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(Constants.primaryTextColor))
                    
                    Text("Terms of Service")
                        .foregroundStyle(Constants.secondaryTextColor)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .padding(20) // Spacing inside the card
                .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                .padding(.horizontal) // Spacing outside the card
                
                Spacer()
                
            }
            
        }
    }

    private func statCard(value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Constants.primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Constants.secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Constants.backgroundSecondaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ProfileView()
}
