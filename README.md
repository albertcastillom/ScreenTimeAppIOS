# ScreenTime

ScreenTime is an iOS focus app built with SwiftUI, Apple's Screen Time APIs, and Supabase. Users choose apps, categories, or websites to block, start a timed session locally, or ask a friend to approve a focus session for them.

> **Project status:** Active development. The core authentication, friends, focus-request, and timed-blocking flows are implemented. Several profile and leaderboard surfaces are still prototypes. This status reflects the repository as of October 3, 2026.

## Current progress

| Area | Status | What works today |
| --- | --- | --- |
| Authentication | Implemented | Email/password sign-up and login, session restoration, sign-out, and account deletion through a Supabase Edge Function |
| Screen Time authorization | Implemented | Requests individual Family Controls authorization before entering the main app |
| App selection | Implemented | Selects apps, categories, and web domains with `FamilyActivityPicker`; the selection is saved locally in the shared App Group |
| Local focus sessions | Implemented | Starts and manually stops timed Managed Settings shields; durations currently range from 15 to 90 minutes |
| Background cleanup | Implemented | A Device Activity Monitor extension removes shields and clears shared session state when a schedule ends |
| Friends | Implemented | Username search, outgoing friend requests, incoming request accept/decline, friend listing, and friend removal |
| Social focus requests | Implemented | Send or cancel requests, view incoming and outgoing pending requests, and accept or decline an incoming request |
| Accepted-request activation | Implemented | Private Supabase Realtime broadcasts start blocking on the requester's device; database reconciliation covers launch, reconnect, and foreground recovery |
| Profile | Partial | Loads the current username, membership year, and live friend count; sign-out and account deletion work |
| Leaderboard and stats | Prototype | Leaderboard entries, session/streak/rank values, filters, notification toggles, profile editing, and legal links are not connected to persistent data yet |
| Automated tests | Not started | No unit or UI test targets are currently included |

## How focus requests work

1. The requester chooses a duration, a local Screen Time selection, and a friend.
2. Supabase stores the request with a `pending` status. The selected apps never leave the requester's device.
3. The friend accepts or declines the request in the app.
4. Acceptance is broadcast on a private Realtime topic scoped to the requester's user ID.
5. The requester applies its saved local selection, schedules the end time, and marks the request `activated` in Supabase.
6. The monitor extension removes the shields when the interval ends, even if the main app is suspended or terminated.

The Realtime connection is the fast path. The app also queries accepted requests after subscribing and whenever it returns to the foreground so an approval is not lost while iOS has suspended the process.

## Tech stack

- Swift and SwiftUI
- Family Controls, Managed Settings, and Device Activity
- Supabase Auth, Postgres, Realtime Broadcast, and Edge Functions
- `supabase-swift` 2.55.1 through Swift Package Manager
- Swift Observation for app and feature state

## Project structure

```text
ScreenTimeAppIOS/
├── ScreenTimeAppIOS/                 # Main iOS app target
│   ├── App/                          # App entry point, auth gate, and tab navigation
│   ├── Features/
│   │   ├── Auth/                     # Authentication UI and service
│   │   ├── Friends/                  # Friends and focus-request coordination
│   │   ├── Home/                     # Home and focus-session screens
│   │   ├── Leaderboard/              # Prototype leaderboard UI
│   │   ├── Profile/                  # Profile and account controls
│   │   └── database/                 # Supabase client, models, queries, and RPC calls
│   └── ScreenTime/                   # Authorization, selection persistence, and shields
├── ScreenTimeMonitor/                # Device Activity Monitor extension
└── ScreenTimeAppIOS.xcodeproj

supabase/
├── functions/delete-account/         # Authenticated account-deletion Edge Function
└── migrations/                       # Versioned database changes
```

## Requirements

- Xcode with an iOS 18.6 or newer SDK
- An Apple Developer team with the Family Controls capability available
- A physical iPhone running iOS 18.6 or newer for meaningful Screen Time testing
- A Supabase project and the Supabase CLI for backend deployment

Screen Time behavior should be tested on a physical device. Simulator support is not sufficient for validating Family Controls authorization, Managed Settings shields, or extension lifecycle behavior.

## Getting started

1. Clone the repository and open `ScreenTimeAppIOS/ScreenTimeAppIOS.xcodeproj` in Xcode.
2. Allow Xcode to resolve the `supabase-swift` package.
3. Select your development team for both the `ScreenTimeAppIOS` and `ScreenTimeMonitor` targets.
4. Configure the same App Group on both targets. The code currently expects `group.com.albertcastillo.ScreenTimeAppIOS`; if you change it, update both entitlement files and `ScreenTimeIdentifiers.swift` in both targets.
5. Enable the Family Controls capability for both targets and use provisioning profiles that contain the entitlement.
6. Set the Supabase project URL and publishable key in `ScreenTimeAppIOS/ScreenTimeAppIOS/Constants/AppConstants.swift`.
7. Select the `ScreenTimeAppIOS` scheme and run on a signed-in physical device.
8. Create an account, grant Screen Time access, choose items to block, and start a local session or send a request to a second test account.

The repository currently contains project-specific Supabase publishable configuration. A publishable key is intended for client use, but backend Row Level Security policies remain responsible for protecting data.

## Supabase setup

The app expects these backend resources:

- `profiles`, `friendships`, and `focus_requests` tables with Row Level Security
- RPCs named `accept_focus_request`, `decline_focus_request`, `cancel_focus_request`, and `mark_focus_request_activated`
- A private Realtime Broadcast policy for requester-scoped focus-request updates
- The authenticated `delete-account` Edge Function with access to a server-side secret or service-role key

The checked-in `initial_remote_schema` migration is a complete baseline pulled from the linked Supabase project. It creates the app's tables, types, constraints, indexes, policies, grants, functions, triggers, and Realtime configuration from an empty database.

For the migration and deployment workflow, see [`supabase/README.md`](supabase/README.md).

## Known gaps and next steps

- Replace the mock leaderboard and profile statistics with real session data.
- Implement profile editing, notification preferences, and legal-document navigation.
- Add the optional todo/note support described in the home-screen copy.
- Improve validation and user-facing authentication errors.
- Add unit tests for state transitions and service behavior, plus device-level UI coverage for the core focus flow.
- Add clearer in-session UI, including remaining time and recovery when another accepted request arrives during an active block.

## Privacy model

The Screen Time selection is encoded into the shared App Group so the app and monitor extension can coordinate on the same device. Focus requests send only user IDs, duration, status, and lifecycle timestamps to Supabase; app, category, and website selections are not uploaded or shared with the approving friend.
