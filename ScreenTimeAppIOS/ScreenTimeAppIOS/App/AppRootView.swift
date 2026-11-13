//
//  AppRootView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/25/26.
//

import SwiftUI
import FamilyControls

struct AppRootView: View {
    
    @Environment(AuthManager.self) private var authManager
    @StateObject private var screenTimeManager = PermissionManager()
    
    var body: some View {
        Group {
            if authManager.isPasswordRecoveryActive {
                ResetPasswordView()
            } else {
                switch authManager.authState {
                case .notDetermined:
                    ProgressView()
                case .notAuthenticated:
                    NavigationStack {
                        if authManager.shouldShowLogin {
                            LoginView()
                        } else {
                            SignUpView()
                        }
                    }
                case .authenticated:
                    //Displays home page
                    VStack{
                        if screenTimeManager.authorizationStatus == .notDetermined {
                            ScreenTimePermissionView(screenTimeManager: screenTimeManager)
                        } else if screenTimeManager.authorizationStatus == .approved {
                            MainTabView()
                        } else {
                            Text("Authorization Denied or Restricted. Please enable in Settings.")
                            // Guide user to Settings if needed
                        }
                    }
                    .onAppear {
                        screenTimeManager.checkAuthorization()
                    }
                    
                case .failed(let message):
                    startupErrorView(message)
                }
            }
        }
        .task {
            await authManager.start()
        }
    }
    
    private func startupErrorView(_ message: String) -> some View {
        
        ZStack {
            Constants.authSurfaceColor.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Constants.AuthPrimaryText)

                Text("Unable to Check Your Session")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.AuthPrimaryText)

                Text(message)
                    .foregroundStyle(Constants.AuthPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    Task {
                        await authManager.loadInitialAuthState()
                    }
                } label: {
                    Text("Try Again")
                        .authPrimaryButtonStyle()
                }
            }
        }
    }
}


#Preview {
    AppRootView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
