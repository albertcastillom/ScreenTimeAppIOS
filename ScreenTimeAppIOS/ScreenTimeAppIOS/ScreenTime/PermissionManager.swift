//
//  ScreenTimeAPIService.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/24/26.
//

import Foundation
import FamilyControls
internal import Combine

@MainActor
final class PermissionManager: ObservableObject {
    @Published private(set) var authorizationStatus: FamilyControls.AuthorizationStatus
    
    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            print("Failed to request Screen Time authorization: \(error)")
        }
    }
    
    func checkAuthorization() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
}
 
