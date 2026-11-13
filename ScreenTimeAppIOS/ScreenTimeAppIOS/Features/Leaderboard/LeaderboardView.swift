//
//  LeaderboardView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var selectedScope: LeaderboardScope = .friends

    var body: some View {
        ZStack {
            Constants.appBackgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                    scopePicker
                    periodPicker
                    leaderboardCard
                }
                .padding(.bottom)
            }
        }
        .task {
            await viewModel.loadLeaderboard()
        }
        .refreshable {
            await viewModel.loadLeaderboard()
        }
    }

    private var header: some View {
        HStack {
            Text("Leaderboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Constants.primaryTextColor)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var scopePicker: some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                Button {
                    selectedScope = scope
                } label: {
                    Label(scope.title, systemImage: scope.systemImage)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .background(
                    selectedScope == scope
                        ? Constants.buttonBackgroundColor
                        : Constants.inputBackgroundColor
                )
                .foregroundStyle(
                    selectedScope == scope
                        ? Constants.buttonForegroundColor
                        : Constants.primaryTextColor
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal)
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            periodButton("This Week", period: .week)
            periodButton("This Month", period: .month)
            periodButton("All Time", period: .allTime)
        }
        .padding(.horizontal)
    }

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedScope.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Constants.textOnYellowColor)

                Spacer()

                Text(periodTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Constants.textOnYellowColor.opacity(0.75))
            }

            if viewModel.isLoading && displayedEntries.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let errorMessage = viewModel.errorMessage,
                      displayedEntries.isEmpty {
                errorContent(errorMessage)
            } else if displayedEntries.isEmpty {
                Text(emptyMessage)
                    .foregroundStyle(Constants.textOnYellowColor)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            } else {
                ForEach(Array(displayedEntries.enumerated()), id: \.element.id) { index, entry in
                    leaderboardRow(entry)

                    if index < displayedEntries.count - 1 {
                        Divider()
                            .overlay(Constants.textOnYellowColor.opacity(0.2))
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
    }

    private func periodButton(_ title: String, period: LeaderboardPeriod) -> some View {
        let isSelected = viewModel.selectedPeriod == period

        return Button {
            Task {
                await viewModel.selectPeriod(period)
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(
            isSelected
                ? Constants.buttonBackgroundColor
                : Constants.inputBackgroundColor
        )
        .foregroundStyle(
            isSelected
                ? Constants.buttonForegroundColor
                : Constants.primaryTextColor
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .disabled(viewModel.isLoading)
    }

    private func leaderboardRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.headline)
                .foregroundStyle(Constants.textOnYellowColor)
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.body)
                    .fontWeight(isCurrentUser(entry) ? .bold : .regular)
                    .foregroundStyle(Constants.textOnYellowColor)

                if isCurrentUser(entry) {
                    Text("You")
                        .font(.caption)
                        .foregroundStyle(Constants.textOnYellowColor.opacity(0.75))
                }
            }

            Spacer()

            Text(formattedDuration(entry.totalMinutes))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Constants.textOnYellowColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Rank \(entry.rank), \(entry.username), \(formattedDuration(entry.totalMinutes))"
        )
    }

    private func errorContent(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .foregroundStyle(Constants.textOnYellowColor)

            Button("Retry") {
                Task {
                    await viewModel.loadLeaderboard()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Constants.cardButtonBackgroundColor)
            .foregroundStyle(Constants.cardButtonForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
    }

    private var displayedEntries: [LeaderboardEntry] {
        switch selectedScope {
        case .friends:
            viewModel.friendLeaderboard
        case .global:
            viewModel.globalLeaderboard
        }
    }

    private var periodTitle: String {
        switch viewModel.selectedPeriod {
        case .week:
            "This Week"
        case .month:
            "This Month"
        case .allTime:
            "All Time"
        }
    }

    private var emptyMessage: String {
        switch selectedScope {
        case .friends:
            "No completed focus time for you or your friends in this period."
        case .global:
            "No opted-in users have completed focus time in this period."
        }
    }

    private func isCurrentUser(_ entry: LeaderboardEntry) -> Bool {
        entry.profileID == viewModel.profile?.id
    }

    private func formattedDuration(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes)m"
        }

        if minutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(minutes)m"
    }
}

private enum LeaderboardScope: CaseIterable {
    case friends
    case global

    var title: String {
        switch self {
        case .friends:
            "Friends"
        case .global:
            "Global"
        }
    }

    var systemImage: String {
        switch self {
        case .friends:
            "person.2"
        case .global:
            "globe"
        }
    }
}

#Preview {
    LeaderboardView()
}
