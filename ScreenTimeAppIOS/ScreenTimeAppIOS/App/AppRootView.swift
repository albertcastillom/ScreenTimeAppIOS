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
            switch authManager.authState {
            case .notDetermined:
                    ProgressView()
            case .notAuthenticated:
                NavigationStack {
                    SignUpView()
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
            }
        }
        .task {
            await authManager.getAuthState()
        }
    }
}

#Preview {
    AppRootView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
