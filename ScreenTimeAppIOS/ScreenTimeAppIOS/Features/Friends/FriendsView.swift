//
//  FriendsView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct FriendsView: View {
    @State private var viewModel: FriendsViewModel
    @State private var isShowingAddFriend = false
    
    private let loadsData: Bool
    
    init() {
        _viewModel = State(initialValue: FriendsViewModel())
        loadsData = true
    }
    
    init(viewModel: FriendsViewModel, loadsData: Bool) {
        _viewModel = State(initialValue: viewModel)
        self.loadsData = loadsData
    }
    
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
                
                //new add friends button
                Button {
                    isShowingAddFriend = true
                } label: {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Constants.buttonBackgroundColor)
                        .foregroundStyle(Constants.buttonForegroundColor)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                }
                .padding(.horizontal)
                .sheet(isPresented: $isShowingAddFriend) {
                    AddFriendView(viewModel: viewModel)
                }
                
                //Share to Friends Link
                if let inviteURL = viewModel.inviteURL {
                    ShareLink(
                        item: inviteURL,
                        subject: Text("Join me on ScreenTime"),
                        message: Text("Tap this link to add me as a friend.")
                    ) {
                        Label("Invite a Friend", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Constants.buttonBackgroundColor)
                            .foregroundStyle(Constants.buttonForegroundColor)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                            )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .task {
            guard loadsData else {
                return
            }
            
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
                
                ForEach(Array(viewModel.friends.enumerated()), id: \.element.id){ index, friend in
                    friendRow(friend)
                    if index < viewModel.friends.count - 1{
                        Divider()
                            .overlay(Constants.textOnYellowColor.opacity(0.25))
                            .padding(.trailing, 16)
                    }
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
            .buttonStyle(.borderedProminent)
            .font(.caption.weight(.semibold))
            .controlSize(.small)
            .tint(Constants.cardButtonBackgroundColor)
            .accessibilityLabel("Remove \(friend.username)")
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
    
}

#Preview {
    let viewModel = FriendsViewModel()

    viewModel.currentProfile = Profile(
        id: UUID(),
        username: "albert",
        createdAt: Date(),
        showOnGlobalLeaderboard: true
    )
    viewModel.friends = [
        Profile(
            id: UUID(),
            username: "jessica",
            createdAt: Date(),
            showOnGlobalLeaderboard: true
        ),
        Profile(
            id: UUID(),
            username: "Chloe",
            createdAt: Date(),
            showOnGlobalLeaderboard: false
        ),
        Profile(
            id: UUID(),
            username: "Kim",
            createdAt: Date(),
            showOnGlobalLeaderboard: true
        ),Profile(
            id: UUID(),
            username: "Javier",
            createdAt: Date(),
            showOnGlobalLeaderboard: true
        ),Profile(
            id: UUID(),
            username: "Bryan",
            createdAt: Date(),
            showOnGlobalLeaderboard: true
        ),
    ]

    return FriendsView(
        viewModel: viewModel,
        loadsData: false
    )
}
