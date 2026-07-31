//
//  ScreenTimePermissionView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/25/26.
//

import SwiftUI
import FamilyControls

struct ScreenTimePermissionView: View {
    
    @StateObject var ScreenTimeManager = PermissionManager()
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack{
                Text("This App needs Screen Time Permissions")
                Button("Request Permissions") {
                    Task {
                        await ScreenTimeManager.requestAuthorization()
                    }
                }
            }
        }
    }
}

#Preview {
    ScreenTimePermissionView()
}
