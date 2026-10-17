//
//  ShieldConfigurationExtension.swift
//  ScreenTimeShieldConfiguration
//
//  Created by Albert Castillo on 10/16/26.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield as needed for applications.
        Self.makeConfiguration()
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for applications shielded because of their category.
        Self.makeConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        Self.makeConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        Self.makeConfiguration()
    }
    
    
    private static func makeConfiguration() -> ShieldConfiguration{
        let brandYellow = UIColor(
            displayP3Red: 1.0,
            green: 226.0 / 255.0,
            blue: 90.0 / 255.0,
            alpha: 1.0
        )
        
        let brandBlack = UIColor(
            displayP3Red: 28.0 / 255.0,
            green: 28.0 / 255.0,
            blue: 26.0 / 255.0,
            alpha: 1.0
        )
        
        let shieldIcon = UIImage(
            systemName: "hourglass.circle.fill"
        )?.withTintColor(
            brandBlack,
            renderingMode: .alwaysOriginal
        )
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: brandYellow,
            icon: shieldIcon,
            title: ShieldConfiguration.Label(text: "Focus Session Active", color: brandBlack),
            subtitle: ShieldConfiguration.Label(text: "Stay Commited. This app is unavaible until the session ends.", color: brandBlack),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Stay Commited", color: brandYellow),
            primaryButtonBackgroundColor: brandBlack,
            secondaryButtonLabel: nil
        )
    }
}
