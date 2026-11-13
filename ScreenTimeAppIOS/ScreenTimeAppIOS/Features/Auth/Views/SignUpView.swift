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
            Constants.authSurfaceColor.ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("Commit: Social App Blocker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.AuthPrimaryText)
                
                Spacer()
                
                Text("Create an Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.AuthPrimaryText)
                Text("Please enter your email address to continue")
                    .font(.body)
                    .foregroundStyle(Constants.AuthPrimaryText)
                TextField("Email Address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .authInputStyle()

                if !email.isEmpty && !isEmailValid {
                    Text("Enter a valid email address to continue.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .accessibilityLabel("Email error: Enter a valid email address to continue.")
                }
            
                NavigationLink{
                    SignupFinishView(email: email)
                        .navigationBarBackButtonHidden()
                } label: {
                    Text("Continue")
                        .authPrimaryButtonStyle()
                }
                .disabled(!isEmailValid)
                .padding(.vertical)
                
                Spacer()
                
                NavigationLink{
                    LoginView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3){
                        Text("Already have an account?")
                            .foregroundStyle(Constants.AuthPrimaryText)
                        
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundStyle(Constants.AuthPrimaryText)
                    }
                }
                
            }
        }
    }
}

private extension SignUpView {
    var isEmailValid: Bool {
        let parts = email.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && parts[0].isEmpty == false && parts[1].contains(".")
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environment(AuthManager(service: SupabaseAuthService()))
}
