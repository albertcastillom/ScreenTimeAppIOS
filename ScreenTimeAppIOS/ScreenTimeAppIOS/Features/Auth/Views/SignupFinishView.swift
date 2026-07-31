//
//  SignupFinishView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/21/26.
//

import SwiftUI

struct SignupFinishView: View {
    
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String
    @State private var username = ""
    @State private var password = ""
    @State private var confirmedPassword = ""
    @State private var passwordsMatch = false
    
    init(email: String) {
        _email = State(initialValue: email)
    }
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                Text("Finish Signing Up")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Please fill out the fields")
                    .font(.body)
                    .foregroundColor(.secondary)
                TextField("Enter your email", text: $email)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                
                TextField("Enter your username", text: $username)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                ZStack(alignment: .trailing){
                    SecureField("Enter your Password", text: $password)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    if !password.isEmpty && !confirmedPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? .green : .red)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 24)
                
                ZStack(alignment: .trailing){
                    SecureField("Confirm your password", text: $confirmedPassword)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    if !password.isEmpty && !confirmedPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? .green : .red)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 24)
                .onChange(of: confirmedPassword){ oldValue, newValue in
                    passwordsMatch = newValue == password
                }
            
                Button{
                    signUp()
                } label: {
                    Text("Sign Up")
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
                        Text("Already have an account?")
                            .foregroundStyle(Constants.secondaryTextColor)
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundStyle(Constants.secondaryTextColor)
                    }
                }
            }
        }
    }
}

private extension SignupFinishView{
    func signUp(){
        Task {
            await authManager.signUp(withEmail: email, password: password, username: username)
        }
    }
}

#Preview {
    SignupFinishView(email: "albert@example.com")
        .environment(AuthManager(service: SupabaseAuthService()))
}
