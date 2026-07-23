//
//  SignUpView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/21/26.
//

import SwiftUI

struct SignUpView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                Text("Create an Account")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Please enter your email address to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
                TextField("Email Address", text: $email)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
            
                NavigationLink{
                    SignupFinishView(email: email)
                        .navigationBarBackButtonHidden()
                } label: {
                    Text("Continue")
                        .frame(width: 360, height: 48)
                        .font(.headline)
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.vertical)
                
                Spacer()
                
                NavigationLink{
                    LoginView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3){
                        Text("Already have an account?")
                            .foregroundStyle(Constants.secondaryTextColor)
                        
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundStyle(Constants.secondaryTextColor)
                    }
                }
                
            }
        }
        .onAppear {
            UserDefaults.standard.removeObject(forKey: "email")
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environment(AuthManager(service: SupabaseAuthService()))
}
