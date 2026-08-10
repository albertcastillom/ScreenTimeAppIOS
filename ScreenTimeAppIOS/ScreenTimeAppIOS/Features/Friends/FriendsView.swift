//
//  FriendsView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendViewModel()
    @State private var searchText = ""
    @State private var isShowingSearch = false

    var body: some View {
       ZStack {
           Color("Background")
               .ignoresSafeArea()
           
           VStack {
               HStack {
                   Text("Friends")
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundStyle(Color("PrimaryText"))

                   Spacer()
               }
               .padding(.horizontal)
               .padding(.top)
               
               if viewModel.isLoading && viewModel.friends.isEmpty && viewModel.pendingRequests.isEmpty {
                   ProgressView()
                       .frame(maxWidth: .infinity, minHeight: 120)
               }

               if let errorMessage = viewModel.errorMessage {
                   Text(errorMessage)
                       .font(.body)
                       .foregroundStyle(Color("SecondaryText"))
                       .padding(.horizontal)
               }
               
               pendingRequestsCard
               friendsCard
               searchCard
               
               Button(isShowingSearch ? "Close Search" : "Add Friends +") {
                   isShowingSearch.toggle()
               }
               .padding()
               .background(.buttonBackground)
               .foregroundColor(.buttonForeground)
               .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
               
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
                .foregroundStyle(Color("PrimaryText"))

            if viewModel.pendingRequests.isEmpty {
                Text("No pending requests")
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                ForEach(viewModel.pendingRequests) { request in
                    pendingRequestRow(request)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private var friendsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friends: \(viewModel.friendsCount)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color("PrimaryText"))

            if viewModel.friends.isEmpty {
                Text("No friends yet")
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                ForEach(viewModel.friends) { friend in
                    friendRow(friend)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isShowingSearch {
                TextField("Search username", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color("Background"))
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
                .background(.buttonBackground)
                .foregroundColor(.buttonForeground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                ForEach(viewModel.searchResults) { profile in
                    searchResultRow(profile)
                }
            }
        }
        .padding(isShowingSearch ? 20 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isShowingSearch ? Color("BackgroundSecondary") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: isShowingSearch ? Color.black.opacity(0.1) : Color.clear, radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private func friendRow(_ friend: Profile) -> some View {
        HStack {
            Text(friend.username)
                .foregroundStyle(Color("PrimaryText"))
            Spacer()
            Button("Remove") {
                Task {
                    await viewModel.removeFriend(friend)
                }
            }
            .font(.caption)
            .foregroundStyle(Color("SecondaryText"))
        }
    }

    private func pendingRequestRow(_ request: Friendship) -> some View {
        HStack {
            Text("Friend request")
                .foregroundStyle(Color("PrimaryText"))
            Spacer()
            Button("Accept") {
                Task {
                    await viewModel.acceptFriendRequest(request)
                }
            }
            Button("Decline") {
                Task {
                    await viewModel.rejectFriendRequest(request)
                }
            }
        }
    }

    private func searchResultRow(_ profile: Profile) -> some View {
        HStack {
            Text(profile.username)
                .foregroundStyle(Color("PrimaryText"))
            Spacer()
            Button("Add") {
                Task {
                    print(profile)
                    await viewModel.sendFriendRequest(to: profile)
                }
            }
            .foregroundStyle(Color("SecondaryText"))
        }
    }
}

#Preview {
    FriendsView()
}
