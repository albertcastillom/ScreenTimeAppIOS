//
//  HomeView.swift
//  ScreenTimeAppIOS
//
//  Created by Albert Castillo on 7/16/26.
//

import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var focusSessionViewModel = FocusRequestsViewModel()
    @Environment(AppBlockingModel.self) private var appBlockingModel
    @State private var activitySelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    
    
    private let blockedAppColumns = [
        GridItem(.adaptive(minimum: 105), spacing: 10)
    ]

    var body: some View {
        @Bindable var appBlockingModel = appBlockingModel
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    //Home and profile Hstack
                    HStack {
                        Text("Home")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("PrimaryText"))

                        Spacer()

                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(Constants.primaryTextColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    //if focus sessions requests are not empty show them
                    if focusSessionViewModel.hasPendingFocusSessions {
                        incomingFocusRequestsCard
                    }

                    if let errorMessage = focusSessionViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    //focus session card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Start a focus Session")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("PrimaryText"))

                        Text("Send a session request to a friend or family member. Add an optional todo list or note to help you stay focused.")
                            .font(.body)
                            .foregroundStyle(Color("SecondaryText"))
                            .lineLimit(3)

                        NavigationLink(destination: SessionView()) {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color("PrimaryText"))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("BackgroundSecondary"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    //Block apps selection card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What Gets Blocked")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Constants.primaryTextColor)

                        if appBlockingModel.blockedSelectionSummary.isEmpty {
                            Text("No apps selected")
                                .font(.body)
                                .foregroundStyle(Constants.secondaryTextColor)
                        } else {
                            LazyVGrid(
                                columns: blockedAppColumns,
                                alignment: .leading,
                                spacing: 10
                            ) {
                                ForEach(appBlockingModel.blockedSelectionSummary, id: \.self) { item in
                                    blockedSelectionBadge(item)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            isPickerPresented = true
                        } label: {
                            Text("Choose Apps to Block")
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .font(.headline)
                                .background(.buttonBackground)
                                .foregroundColor(.buttonForeground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .familyActivityPicker(
                            isPresented: $isPickerPresented,
                            selection: $appBlockingModel.activitySelection
                        )
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Constants.backgroundSecondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)

                    Spacer(minLength: 0)
                }
            }
        }
        .task {
            await focusSessionViewModel.loadFocusSessionScreen()
        }
        .onAppear {
            appBlockingModel.refreshBlockingState()
            activitySelection = appBlockingModel.activitySelection
        }
        .onChange(of: activitySelection) { _, newSelection in
            appBlockingModel.updateActivitySelection(newSelection)
        }
    }

    private var incomingFocusRequestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Requests")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color("PrimaryText"))

            ForEach(focusSessionViewModel.pendingFocusSessions) { request in
                incomingFocusRequestRow(request)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private func incomingFocusRequestRow(_ request: FocusRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Constants.primaryTextColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(focusSessionViewModel.usernameForPendingFocusSessionRequest(request))
                        .font(.headline)
                        .foregroundStyle(Constants.primaryTextColor)

                    Text("\(request.durationMinutes) min • Pending")
                        .font(.subheadline)
                        .foregroundStyle(Constants.secondaryTextColor)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await focusSessionViewModel.rejectFocusSessionRequest(request)
                    }
                } label: {
                    Text("Decline")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Constants.buttonBackColor)
                        .foregroundColor(Constants.buttonForeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    Task {
                        await focusSessionViewModel.acceptFocusSessionRequest(request)
                    }
                } label: {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(.buttonBackground)
                        .foregroundColor(.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

private func blockedSelectionBadge(_ summary: String) -> some View {
    Text(summary)
        .font(.body)
        .fontWeight(.semibold)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Constants.secondaryTextColor)
        .foregroundColor(Constants.buttonForeColor)
        .clipShape(Capsule())
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AuthManager(service: SupabaseAuthService()))
    .environment(AppBlockingModel())
}
