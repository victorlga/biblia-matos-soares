//
//  HapticManager.swift
//  biblia-matos-soares
//
//  Centralized haptic feedback management
//

import UIKit

/// Manages haptic feedback throughout the app, respecting user preferences
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    /// Check if haptic feedback is enabled in user settings
    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
    }

    /// Trigger impact haptic feedback
    /// - Parameter style: The style of impact (.light, .medium, .heavy, .soft, or .rigid)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger notification haptic feedback
    /// - Parameter type: The type of notification (.success, .warning, or .error)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Trigger selection haptic feedback (for picker/selector changes)
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
