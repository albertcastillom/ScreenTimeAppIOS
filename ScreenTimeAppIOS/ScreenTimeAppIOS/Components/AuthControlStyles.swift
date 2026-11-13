//
//  AuthControlStyles.swift
//  ScreenTimeAppIOS
//

import SwiftUI

private enum AuthControlLayout {
    static let height: CGFloat = 48
    static let cornerRadius: CGFloat = 16
    static let horizontalInset: CGFloat = 16
    static let contentInset: CGFloat = 12
}

private struct AuthInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(.horizontal, AuthControlLayout.contentInset)
            .frame(maxWidth: .infinity)
            .frame(height: AuthControlLayout.height)
            .background(Constants.inputBackgroundColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AuthControlLayout.cornerRadius,
                    style: .continuous
                )
            )
            .padding(.horizontal, AuthControlLayout.horizontalInset)
    }
}

private struct AuthPrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: AuthControlLayout.height)
            .font(.headline)
            .background(Constants.buttonBackgroundColor)
            .foregroundStyle(Constants.buttonForegroundColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AuthControlLayout.cornerRadius,
                    style: .continuous
                )
            )
            .padding(.horizontal, AuthControlLayout.horizontalInset)
    }
}

extension View {
    func authInputStyle() -> some View {
        modifier(AuthInputStyle())
    }

    func authPrimaryButtonStyle() -> some View {
        modifier(AuthPrimaryButtonStyle())
    }
}
