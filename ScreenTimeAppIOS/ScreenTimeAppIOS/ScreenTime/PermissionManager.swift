//
//  ScreenTimeAPIService.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/24/26.
//

import Foundation
import FamilyControls
internal import Combine

class PermissionManager: ObservableObject {
    @Published var authorizationStatus: FamilyControls.AuthorizationStatus = .notDetermined
    
    init() {
        Task {
            await checkAuthorization()
        }
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            print ("Failed to request authorization")
            self.authorizationStatus = .denied
        }
    }
    
    func checkAuthorization() async {
        self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
}
 
