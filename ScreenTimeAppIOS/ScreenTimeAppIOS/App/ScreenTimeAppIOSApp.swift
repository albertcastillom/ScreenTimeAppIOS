//
//  ScreenTimeAppIOSApp.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

@main
struct ScreenTimeAppIOSApp: App {
    
    @State private var authManager = AuthManager(service: SupabaseAuthService())
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}
