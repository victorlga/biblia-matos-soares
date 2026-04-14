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

    /// Trigger impact haptic feedback
    /// - Parameter style: The style of impact (.light, .medium, .heavy, .soft, or .rigid)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger notification haptic feedback
    /// - Parameter type: The type of notification (.success, .warning, or .error)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Trigger selection haptic feedback (for picker/selector changes)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
