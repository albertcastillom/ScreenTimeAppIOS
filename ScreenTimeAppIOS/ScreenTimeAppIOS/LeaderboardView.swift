//
//  LeaderboardView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct LeaderboardView: View {
    var body: some View {
       ZStack {
           Color("Background").ignoresSafeArea(edges: .all)
           
           VStack {
               HStack {
                   Text("Leaderboard")
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundStyle(Color("PrimaryText"))

                   Spacer()
               }
               .padding(.horizontal)
               .padding(.top)
               
               HStack(spacing: 8) {
                   filterButton("This Week")
                   filterButton("This Month")
                   filterButton("All Time")
               }
               .padding(.horizontal)
               
               VStack(alignment: .leading, spacing: 12) {
    
                   HStack{
                       Text("Mia Kim")
                           .foregroundStyle(Color("PrimaryText"))
                       
                       Spacer()
                       
                       Text("52 Hrs")
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

    private func filterButton(_ title: String) -> some View {
        Button {
            print("Selected \(title)")
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(.buttonBackground)
        .foregroundColor(.buttonForeground)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }
}

#Preview {
    LeaderboardView()
}
