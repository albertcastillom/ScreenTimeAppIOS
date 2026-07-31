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
    @StateObject var ScreenTimeManager = PermissionManager()
    
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
                    if ScreenTimeManager.authorizationStatus == .notDetermined {
                        ScreenTimePermissionView()
                    } else if ScreenTimeManager.authorizationStatus == .approved {
                        MainTabView()
                    } else {
                        Text("Authorization Denied or Restricted. Please enable in Settings.")
                        // Guide user to Settings if needed
                    }
                }
                .onAppear {
                    Task {
                        await ScreenTimeManager.checkAuthorization()
                    }
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
