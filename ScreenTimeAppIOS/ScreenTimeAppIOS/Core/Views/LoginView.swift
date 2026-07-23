//
//  LoginView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/21/26.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
        
            VStack {
                
                Spacer()
                
                Text("Login In")
                    .font(.title)
                    .fontWeight(.bold)
                TextField("Email Address", text: .constant(""))
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                
                SecureField("Enter your password", text: $password)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                
                Button{
                        print("logged in")
                } label: {
                    Text("Login")
                        .frame(width: 360, height: 48)
                        .font(.headline)
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.vertical)
                
                Spacer()
                
                Button { dismiss() } label: {
                    HStack(spacing: 3){
                        Text("Dont have an account?")
                            .foregroundStyle(Constants.secondaryTextColor)
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundStyle(Constants.secondaryTextColor)
                        }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
