//
//  FriendsView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var searchText = ""
    @State private var isShowingSearch = false

    var body: some View {
       ZStack {
           Constants.appBackgroundColor
               .ignoresSafeArea()
           
           VStack {
               //Friends Title
               HStack {
                   Text("Friends")
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundStyle(Constants.primaryTextColor)

                   Spacer()
               }
               .padding(.horizontal)
               .padding(.top)
               
               //if no friend requests card is hidden
               if viewModel.isLoading && viewModel.friends.isEmpty && viewModel.pendingRequests.isEmpty {
                   ProgressView()
                       .frame(maxWidth: .infinity, minHeight: 120)
               }

               if let errorMessage = viewModel.errorMessage {
                   Text(errorMessage)
                       .font(.body)
                       .foregroundStyle(Constants.secondaryTextColor)
                       .padding(.horizontal)
               }
               
               if !viewModel.pendingRequests.isEmpty{
                   pendingRequestsCard
               }
              
               friendsCard
               
               searchCard
               
               //Add friends button
               Button {
                   isShowingSearch.toggle()
               } label: {
                   Text(isShowingSearch ? "Close Search" : "Add Friend +")
                       .frame(maxWidth: .infinity, minHeight: 48)
                       .background(Constants.buttonBackgroundColor)
                       .foregroundStyle(Constants.buttonForegroundColor)
                       .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                       .padding(.horizontal)
               }
               
               Spacer()
           }
        }
       .task {
           await viewModel.loadFriendsScreen()
       }
    }

    private var pendingRequestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Requests")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Constants.textOnYellowColor)

            if viewModel.pendingRequests.isEmpty {
                Text("No pending requests")
                    .foregroundStyle(Constants.textOnYellowColor)
            } else {
                ForEach(viewModel.pendingRequests) { request in
                    pendingRequestRow(request)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private var friendsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friends: \(viewModel.friendsCount)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Constants.textOnYellowColor)

            if viewModel.friends.isEmpty {
                Text("No friends yet")
                    .foregroundStyle(Constants.textOnYellowColor)
            } else {
                ForEach(viewModel.friends) { friend in
                    friendRow(friend)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.bottom)
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isShowingSearch {
                TextField("Search username", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Constants.inputBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onSubmit {
                        Task {
                            await viewModel.searchProfiles(usernameQuery: searchText)
                        }
                    }

                Button("Search") {
                    Task {
                        await viewModel.searchProfiles(usernameQuery: searchText)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(Constants.cardButtonBackgroundColor)
                .foregroundStyle(Constants.cardButtonForegroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                ForEach(viewModel.searchResults) { profile in
                    searchResultRow(profile)
                }
            }
        }
        .padding(isShowingSearch ? 20 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isShowingSearch ? Constants.cardBackgroundColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: isShowingSearch ? Color.black.opacity(0.1) : Color.clear, radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private func friendRow(_ friend: Profile) -> some View {
        HStack {
            Text(friend.username)
                .foregroundStyle(Constants.textOnYellowColor)
            Spacer()
            Button("Remove") {
                Task {
                    await viewModel.removeFriend(friend)
                }
            }
            .font(.caption)
            .foregroundStyle(Constants.textOnYellowColor)
        }
    }

    private func pendingRequestRow(_ request: Friendship) -> some View {
        HStack {
            Text(viewModel.usernameForPendingRequest(request))
                .foregroundStyle(Constants.textOnYellowColor)
            Spacer()
            Button("Accept") {
                Task {
                    await viewModel.acceptFriendRequest(request)
                }
            }
            .foregroundStyle(Constants.textOnYellowColor)
            Button("Decline") {
                Task {
                    await viewModel.rejectFriendRequest(request)
                }
            }
            .foregroundStyle(Constants.textOnYellowColor)
        }
    }

    private func searchResultRow(_ profile: Profile) -> some View {
        HStack {
            Text(profile.username)
                .foregroundStyle(Constants.textOnYellowColor)
            Spacer()
            Button("Add") {
                Task {
                    print(profile)
                    await viewModel.sendFriendRequest(to: profile)
                }
            }
            .foregroundStyle(Constants.textOnYellowColor)
        }
    }
}

#Preview {
    FriendsView()
}
