//
//  HomeView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var appBlockingModel = AppBlockingModel()
    
    var body: some View {
        @Bindable var appBlockingModel = appBlockingModel

        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("PrimaryText"))

                    Spacer()

                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Constants.primaryTextColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                VStack(alignment: .leading, spacing: 12) {
                    // Card Title
                    Text("Start a focus Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("PrimaryText"))

                    // Card Description
                    Text("Send a session request to a friend or family member. Add an optional todo list or note to help you stay focused.")
                        .font(.body)
                        .foregroundStyle(Color("SecondaryText"))
                        .lineLimit(3) // Keeps layout consistent

            
                    NavigationLink(destination: SessionView(appBlockingModel: appBlockingModel)){
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color("PrimaryText"))
                    }
                }
                .padding(20) // Spacing inside the card
                .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                .padding(.horizontal) // Spacing outside the card

                Button{
                    Task {
                        await authManager.signOut()
                    }
                } label: {
                    Text("Sign Out")
                        .frame(width: 360, height: 48)
                        .font(.headline)
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Button{
                    appBlockingModel.presentAppPicker()
                } label: {
                    Text("Choose Apps to Block")
                        .frame(width: 360, height: 48)
                        .font(.headline)
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .familyActivityPicker(
                    isPresented: $appBlockingModel.isPickerPresented,
                    selection: $appBlockingModel.activitySelection
                )
                
                
                Spacer()
            }
        }
    }
}


#Preview {
    NavigationStack {
        HomeView()
            .environment(AuthManager(service: SupabaseAuthService()))
    }
}
