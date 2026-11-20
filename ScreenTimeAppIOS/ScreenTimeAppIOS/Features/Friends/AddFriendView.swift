//
//  AddFriendView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 11/19/26.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FriendsViewModel

    @State private var searchText = ""
    init(
        viewModel: FriendsViewModel,
        initialSearchText: String = ""
    ) {
        _viewModel = Bindable(wrappedValue: viewModel)
        _searchText = State(initialValue: initialSearchText)
    }

    var body: some View {
        NavigationStack {
            resultsList
                .navigationTitle("Add Friend")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search by username"
                )
                .onSubmit(of: .search) {
                    search()
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onDisappear {
            viewModel.searchResults = []
        }
    }

    private var resultsList: some View {
        ScrollView {
               if searchText.isEmpty {
                   emptySearchView
               } else if viewModel.searchResults.isEmpty {
                   ContentUnavailableView.search(text: searchText)
                       .padding(.top, 80)
               } else {
                   searchResultsCard
               }
           }
           .background(Constants.appBackgroundColor)
    }

    private var emptySearchView: some View {
        ContentUnavailableView(
            "Find a Friend",
            systemImage: "person.crop.circle.badge.plus",
            description: Text(
                "Enter an exact username or part of a username."
            )
        )
        .padding(.top, 80)
    }
    
    private var searchResultsCard: some View {
        LazyVStack(spacing: 0) {
            ForEach(
                Array(viewModel.searchResults.enumerated()),
                id: \.element.id
            ) { index, profile in
                resultRow(profile)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                if index < viewModel.searchResults.count - 1 {
                    Divider()
                        .overlay(
                            Constants.textOnYellowColor.opacity(0.25)
                        )
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                }
            }
        }
        .background(Constants.cardBackgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                Constants.textOnYellowColor.opacity(0.1),
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
        .padding()
    }
    
    private func resultRow(_ profile: Profile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(Constants.textOnYellowColor)

            Text(profile.username)
                .foregroundStyle(Constants.textOnYellowColor)

            Spacer()

            Button("Add") {
                Task {
                    await viewModel.sendFriendRequest(to: profile)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.cardButtonBackgroundColor)
            .accessibilityLabel("Add \(profile.username)")
        }
        .padding(.vertical, 4)
    }

    private func search() {
        Task {
            await viewModel.searchProfiles(
                usernameQuery: searchText
            )
        }
    }
}

#Preview("Search Results") {
    let viewModel = FriendsViewModel()

    viewModel.searchResults = [
        Profile(
            id: UUID(),
            username: "samantha",
            createdAt: Date(),
            showOnGlobalLeaderboard: true
        ),
        Profile(
            id: UUID(),
            username: "samuel",
            createdAt: Date(),
            showOnGlobalLeaderboard: false
        )
    ]

    return AddFriendView(
        viewModel: viewModel,
        initialSearchText: "sam"
    )
}

#Preview("Empty Search") {
    AddFriendView(
        viewModel: FriendsViewModel()
    )
}
