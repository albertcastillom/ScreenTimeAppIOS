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
    //focused state vars and accesibility
    @State private var showSignupFinish = false
    @FocusState private var isEmailFocused: Bool
    
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
                    .focused($isEmailFocused)
                    .submitLabel(.next)
                    .onSubmit(continueToSignup)
                    .accessibilityLabel("Email address")
                    .authInputStyle()

                if !email.isEmpty && !isEmailValid {
                    Text("Enter a valid email address to continue.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .accessibilityLabel("Email error: Enter a valid email address to continue.")
                }
            
                Button(action: continueToSignup) {
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
        .navigationDestination(isPresented: $showSignupFinish){
            SignupFinishView(email: email)
                .navigationBarBackButtonHidden()
        }
    }
}

private extension SignUpView {
    var isEmailValid: Bool {
        let parts = email.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && parts[0].isEmpty == false && parts[1].contains(".")
    }
    
    func continueToSignup(){
        guard isEmailValid else{
            isEmailFocused = true
            return
        }
        
        isEmailFocused = false
        showSignupFinish = true
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environment(AuthManager(service: SupabaseAuthService()))
}
