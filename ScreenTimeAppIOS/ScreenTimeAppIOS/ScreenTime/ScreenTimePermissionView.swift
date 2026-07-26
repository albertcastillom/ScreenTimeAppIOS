//
//  ScreenTimePermissionView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/25/26.
//

import SwiftUI
import FamilyControls

struct ScreenTimePermissionView: View {
    
    @StateObject var ScreenTimeManager = AuthorizationManager()
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            Text("This App needs Screen Time Permissions")
            Button("Request Permissions") {
                Task {
                    await ScreenTimeManager.requestAuthorization()
                }
            }
        }
    }
}

#Preview {
    ScreenTimePermissionView()
}
