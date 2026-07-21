//
//  HomeView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
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

                    Button {
                        print("Button tapped!")
                    } label: {
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

                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
