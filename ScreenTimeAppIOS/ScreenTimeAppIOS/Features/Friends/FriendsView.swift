//
//  FriendsView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct FriendsView: View {
    var body: some View {
       ZStack {
           Color("Background")
               .ignoresSafeArea()
           
           VStack {
               HStack {
                   Text("Friends")
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundStyle(Color("PrimaryText"))

                   Spacer()
               }
               .padding(.horizontal)
               .padding(.top)
               
               VStack(alignment: .leading, spacing: 12) {
                   // Card Title
                   Text("Pending Requests")
                       .font(.title2)
                       .fontWeight(.bold)
                       .foregroundStyle(Color("PrimaryText"))
                   HStack {
                       Text("No pending requests")
                           .foregroundStyle(Color("SecondaryText"))
                   }
               }
               .padding(20) // Spacing inside the card
               .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
               .background(Color("BackgroundSecondary"))
               .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
               .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
               .padding(.horizontal) // Spacing outside the card
               
               
               VStack(alignment: .leading, spacing: 12) {
                   // Card Title
                   Text("Friends: 1")
                       .font(.title2)
                       .fontWeight(.bold)
                       .foregroundStyle(Color("PrimaryText"))
                   HStack{
                       Text("Mia Kim")
                           .foregroundStyle(Color("PrimaryText"))
                       Spacer()
                       Text("Sessions: 10")
                           .foregroundStyle(Color("PrimaryText"))
                        Text("Streak: 5")
                           .foregroundStyle(Color("PrimaryText"))
                   }
                
               }
               .padding(20) // Spacing inside the card
               .frame(maxWidth: .infinity, alignment: .leading) // Fills available horizontal width
               .background(Color("BackgroundSecondary"))
               .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Smooth corners
               .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5) // Soft drop shadow
               .padding(.horizontal) // Spacing outside the card
               
               
               Button("Add Friends +") {
                   print("ADD Friends")
               }
               .padding()
               .background(.buttonBackground)
               .foregroundColor(.buttonForeground)
               .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
               
               Spacer()
           }
        
        }
    }
}

#Preview {
    FriendsView()
}
