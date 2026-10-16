//
//  ScreenTimePermissionView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/25/26.
//

import SwiftUI
import FamilyControls

struct ScreenTimePermissionView: View {
    @ObservedObject var screenTimeManager: PermissionManager
    
    var body: some View {
        ZStack {
            Constants.appBackgroundColor
                .ignoresSafeArea()
            
            VStack{
                Text("This App needs Screen Time Permissions")
                    .foregroundStyle(Constants.primaryTextColor)
                Button("Request Permissions") {
                    Task {
                        await screenTimeManager.requestAuthorization()
                    }
                }
                .foregroundStyle(Constants.accentColor)
            }
        }
    }
}

#Preview {
    ScreenTimePermissionView(screenTimeManager: PermissionManager())
}
