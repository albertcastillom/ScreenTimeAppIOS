//
//  LoginView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/21/26.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ZStack {
            Constants.appBackgroundColor.ignoresSafeArea()
        
            VStack {
                Spacer()
                Text("Commit: Social App Blocker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.primaryTextColor)
                Spacer()
                
                Text("Login In")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.primaryTextColor)
                TextField("Email Address", text: $email)
                    .font(.subheadline)
                    .padding(12)
                    .background(Constants.inputBackgroundColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                
                SecureField("Enter your password", text: $password)
                    .font(.subheadline)
                    .padding(12)
                    .background(Constants.inputBackgroundColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                
                Button{
                        login()
                } label: {
                    Text("Login")
                        .frame(width: 360, height: 48)
                        .font(.headline)
                        .background(Constants.buttonBackgroundColor)
                        .foregroundStyle(Constants.buttonForegroundColor)
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

private extension LoginView{
    func login(){
        Task {
            await authManager.login(withEmail: email, password: password)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthManager(service: SupabaseAuthService()))
    }
}
