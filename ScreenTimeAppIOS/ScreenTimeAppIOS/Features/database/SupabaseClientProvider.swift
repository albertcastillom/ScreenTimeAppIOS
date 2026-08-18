//
//  SupabaseClientProvider.swift
//  ScreenTimeAppIOS
//

import Foundation
import Supabase

/// Owns the app's single Supabase client for the lifetime of the process.
///
/// Auth, database, Functions, and Realtime must share this client so they use
/// the same session and no asynchronous Auth work outlives a short-lived client.
enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        guard let projectURL = URL(string: AppConstants.projectURLString) else {
            preconditionFailure("Invalid Supabase project URL")
        }

        return SupabaseClient(
            supabaseURL: projectURL,
            supabaseKey: AppConstants.projectAPIKey
        )
    }()
}
