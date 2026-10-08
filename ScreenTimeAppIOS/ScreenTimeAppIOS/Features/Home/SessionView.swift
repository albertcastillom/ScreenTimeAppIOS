//
//  SessionView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI
import FamilyControls

struct SessionView: View {
    //grid util
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    private let durations = [15, 25, 30, 45, 60, 90]
    
    //state vars
    @Environment(AppBlockingModel.self) private var appBlockingModel
    @State private var focusSessionViewModel = FocusRequestsViewModel()
    @State private var selectedFriend: Profile?
    @State private var selectedDurationMinutes: Int?
    
    var body: some View {
        @Bindable var appBlockingModel = appBlockingModel

        ZStack {
            Color("Background").ignoresSafeArea(edges: .all)

            ScrollView {
                VStack {
                    //Page Title
                    HStack {
                        Text("Start Focus Session")
                            .font(.title)
                            .bold()
                            .foregroundColor(Constants.primaryTextColor)
                            .padding()

                        Spacer()
                    }
                    
                    //Duration Selections
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Constants.primaryTextColor)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(durations, id: \.self) { minutes in
                                durationButton(minutes: minutes)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Constants.backgroundSecondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    //friends to notify card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose a friend to notify")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Constants.primaryTextColor)

                        Text("They'll get a request to start a session with you")
                            .foregroundStyle(Constants.secondaryTextColor)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(focusSessionViewModel.friends) { friend in
                                friendSelectionRow(friend)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Constants.backgroundSecondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)

                    if focusSessionViewModel.hasSentFocusSessions {
                        sentFocusRequestsCard
                    }
                    
                    //error messages with focus request
                    if let errorMessage = focusSessionViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    //local block apps button(move later)
                    Button {
                        toggleLocalFocusSession()
                    } label: {
                        Text(appBlockingModel.isBlocking ? "Stop" : "Start Local Block")
                            .frame(width: 360, height: 48)
                            .font(.headline)
                            .background(.buttonBackground)
                            .foregroundColor(.buttonForeground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    //send request to a friend
                    Button {
                        Task {
                            await focusSessionViewModel.sendFocusSessionRequest(
                                to: selectedFriend,
                                durationMinutes: selectedDurationMinutes
                            )
                        }
                    } label: {
                        Text("Send Request")
                            .frame(width: 360, height: 48)
                            .font(.headline)
                            .background(.buttonBackground)
                            .foregroundColor(.buttonForeground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Spacer()
                }
            }
        }
        .task {
            await focusSessionViewModel.loadFocusSessionScreen()
        }
    }

    private var sentFocusRequestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Approval")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Constants.primaryTextColor)

            ForEach(focusSessionViewModel.sentFocusSessions) { request in
                sentFocusRequestRow(request)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.backgroundSecondaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private func sentFocusRequestRow(_ request: FocusRequest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(Constants.primaryTextColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(focusSessionViewModel.usernameForSentFocusSessionRequest(request))
                    .font(.headline)
                    .foregroundStyle(Constants.primaryTextColor)

                Text("\(request.durationMinutes) min • \(request.status.rawValue.capitalized)")
                    .font(.subheadline)
                    .foregroundStyle(Constants.secondaryTextColor)
            }

            Spacer()

            Button {
                Task {
                    await focusSessionViewModel.cancelFocusSessionRequest(request)
                }
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Constants.buttonBackColor)
                    .foregroundColor(Constants.buttonForeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func durationButton(minutes: Int) -> some View {
        let isSelected = selectedDurationMinutes == minutes

        return Button {
            selectedDurationMinutes = minutes
        } label: {
            Text("\(minutes) min")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isSelected ? Constants.buttonForeColor : Constants.buttonBackColor)
                .foregroundColor(isSelected ? Constants.buttonBackColor : Constants.buttonForeColor)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private func friendSelectionRow(_ friend: Profile) -> some View {
        let isFriendSelected = selectedFriend?.id == friend.id

        return Button {
            selectedFriend = friend
        } label: {
            HStack {
                Image(systemName: isFriendSelected ? "checkmark.circle.fill" : "person.crop.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Constants.primaryTextColor)

                Text(friend.username)
                    .foregroundStyle(Constants.primaryTextColor)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleLocalFocusSession() {
        if appBlockingModel.isBlocking {
            appBlockingModel.stopFocusSession()
        } else if let selectedDurationMinutes {
            appBlockingModel.startFocusSession(durationMinutes: selectedDurationMinutes)
        } else {
            focusSessionViewModel.errorMessage = "Choose a duration first."
        }
    }
}

#Preview {
    SessionView()
        .environment(AppBlockingModel())
        .environment(AuthManager(service: SupabaseAuthService()))
}
