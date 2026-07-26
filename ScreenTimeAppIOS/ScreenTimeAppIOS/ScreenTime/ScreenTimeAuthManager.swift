//
//  ScreenTimeAPIService.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/24/26.
//

import Foundation
import FamilyControls
import ManagedSettings
internal import Combine
import SwiftUI

class AuthorizationManager: ObservableObject {
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
 
//Resuable Profile Editor View
struct ProfileEditorView: View {
    //state to store the users selection
    @State private var activitySelection = FamilyActivitySelection()
    
    //state to control the presentation of the picker
    @State private var isPickerPresented = false
    
    var body: some View {
        VStack{
            Text("Selected \(activitySelection.applicationTokens.count) apps,  \(activitySelection.categoryTokens.count) categories, \(activitySelection.webDomainTokens.count) websites")
            Button("Select Apps & Websites"){
                isPickerPresented = true
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $activitySelection)
        .onChange(of: activitySelection) {
            //handle the udated selection - maybe save it?
            print("selection Updated")
        }
    }
}
