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
            Constants.backgroundColor.ignoresSafeArea(edges: .all)
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
                HStack(spacing: 12) {
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
                        .foregroundStyle(Color(Constants.primaryTextColor))
                    HStack {
                        Text("Push Notifications")
                            .foregroundStyle(Constants.secondaryTextColor)
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                    }
                    HStack {
                        Text("Friend Requests")
                            .foregroundStyle(Constants.secondaryTextColor)
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                //Privacy Policy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Policy")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(Constants.primaryTextColor))
                    
                    Text("Terms of Service")
                        .foregroundStyle(Constants.secondaryTextColor)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("BackgroundSecondary"))
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
                        .frame(width: 360, height: 48)
                        .font(.headline)
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
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
        .background(Constants.backgroundSecondaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private func profileContent(_ profile: Profile) -> some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(Constants.primaryTextColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.username)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.secondaryTextColor)
                
                Text(memberSinceText(for: profile.createdAt))
                    .font(.body)
                    .foregroundStyle(Constants.secondaryTextColor)
            }
            Spacer()
                
            Button("Edit") {
                print("edit Profile")
            }
            .padding()
            .background(.buttonBackground)
            .foregroundColor(.buttonForeground)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        }
    }

    private var profileErrorContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.errorMessage ?? "Profile unavailable")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Constants.secondaryTextColor)

            Button("Retry") {
                Task {
                    await viewModel.loadProfile()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.buttonBackground)
            .foregroundColor(.buttonForeground)
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
                .foregroundStyle(Constants.primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Constants.secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Constants.backgroundSecondaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager(service: SupabaseAuthService()))
}
