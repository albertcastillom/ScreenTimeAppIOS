//
//  HomeView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack{
            HStack{
                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding()
                        .foregroundStyle(.black)
                }
            }
        }
        
        VStack(alignment: .leading, spacing: 12) {
                    // Card Title
                    Text("Start a focus Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    // Card Description
                    Text("Send a session request to a friend or family member. Add an optional todo list or note to help you stay focused.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3) // Keeps layout consistent
                    
                    Button {
                        print("Button tapped!")
                    } label: {
                       Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding(20) // Spacing inside the card
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) // Fills available horizontal width
                .background(Color(.systemBackground)) // Adapts to Dark Mode automatically
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
                .padding(.horizontal) // Spacing outside the card
                .aspectRatio(2, contentMode: .fit)
        
        Spacer()
    }
}

#Preview {
    HomeView()
}
