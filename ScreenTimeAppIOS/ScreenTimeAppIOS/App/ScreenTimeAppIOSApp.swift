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
    @State private var inviteRouter = InviteRouter()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authManager)
                .environment(inviteRouter)
                .onOpenURL { url in
                    if !inviteRouter.handle(url) {
                        Task {
                            await authManager.handleAuthCallback(url)
                        }
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else {
                        return
                    }

                    inviteRouter.handle(url)
                }
        }
    }
}
