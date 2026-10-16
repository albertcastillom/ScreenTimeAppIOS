//
//  ProfileView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ProfileViewModel()
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        ZStack {
            Constants.appBackgroundColor.ignoresSafeArea(edges: .all)
            VStack {
                HStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.primaryTextColor)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                profileCard
                
                //Stats card
                HStack(spacing: 8) {
                    statCard(value: "20", title: "Sessions")
                    statCard(value: "3d", title: "Streak")
                    statCard(value: "\(viewModel.friendsCount)", title: "Friends")
                    statCard(value: "#4", title: "Rank")
                }
                .padding(.horizontal)
                
                
                // Notification card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.textOnYellowColor)
                    HStack {
                        Text("Push Notifications")
                            .foregroundStyle(Constants.textOnYellowColor)
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                            .tint(Constants.cardButtonBackgroundColor)
                    }
                    HStack {
                        Text("Friend Requests")
                            .foregroundStyle(Constants.textOnYellowColor)
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                            .tint(Constants.cardButtonBackgroundColor)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Constants.cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                //Privacy Policy
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.textOnYellowColor)
                    Text("Privacy Policy")
                        .foregroundStyle(Constants.textOnYellowColor)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text("Terms of Service")
                        .foregroundStyle(Constants.textOnYellowColor)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Constants.cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                //Signout Button
                Button {
                    Task {
                        await authManager.signOut()
                    }
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .font(.headline)
                .background(Constants.buttonBackgroundColor)
                .foregroundStyle(Constants.buttonForegroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                
                //Delete account
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    if authManager.isDeletingAccount {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Delete Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(authManager.isDeletingAccount)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.red.opacity(0.12))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .alert("Delete your account?", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                Task {
                    await authManager.deleteAccount()
                }
            }
        } message: {
            Text("This permanently deletes your account, profile, friendships, and focus requests. This action cannot be undone.")
        }
        .alert(
            "Unable to Delete Account",
            isPresented: Binding(
                get: { authManager.accountDeletionError != nil },
                set: { isPresented in
                    if !isPresented {
                        authManager.accountDeletionError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authManager.accountDeletionError ?? "Please try again.")
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading && viewModel.profile == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 64)
            } else if let profile = viewModel.profile {
                profileContent(profile)
            } else {
                profileErrorContent
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private func profileContent(_ profile: Profile) -> some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(Constants.textOnYellowColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.username)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.textOnYellowColor)
                
                Text(memberSinceText(for: profile.createdAt))
                    .font(.body)
                    .foregroundStyle(Constants.textOnYellowColor)
            }
            Spacer()
                
            Button("Edit") {
                print("edit Profile")
            }
            .padding()
            .background(Constants.cardButtonBackgroundColor)
            .foregroundStyle(Constants.cardButtonForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        }
    }

    private var profileErrorContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.errorMessage ?? "Profile unavailable")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Constants.textOnYellowColor)

            Button("Retry") {
                Task {
                    await viewModel.loadProfile()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Constants.cardButtonBackgroundColor)
            .foregroundStyle(Constants.cardButtonForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func memberSinceText(for date: Date?) -> String {
        guard let date else {
            return "Member since unknown"
        }

        let year = Calendar.current.component(.year, from: date)
        return "Member since \(year)"
    }

    private func statCard(value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Constants.textOnYellowColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Constants.textOnYellowColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(Constants.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
