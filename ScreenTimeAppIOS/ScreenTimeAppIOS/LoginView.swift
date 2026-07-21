//
//  LoginView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/20/26.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            VStack {
                Text("Create an Account")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Please enter your email address to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
                TextField("Email Address", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Continue") {
                    print("logged in")
                }
                .padding()
                .background(.buttonBackground)
                .foregroundColor(.buttonForeground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
            }
        }
    }
}

#Preview {
    LoginView()
}
