import SwiftUI
import UIKit

// MARK: - Settings View
struct SettingsView: View {
    private static let genericOpenErrorMessage = "Desculpe, não foi possível abrir o link."

    @Environment(\.dismiss) private var dismiss
    @Binding var hapticFeedbackEnabled: Bool
    @State private var showURLErrorAlert = false
    @State private var urlErrorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                    // Haptic feedback toggle
                    settingsRow(
                        icon: "hand.tap.fill",
                        title: "Feedback tátil",
                        showToggle: true
                    )

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Rate on App Store
                    Button {
                        rateOnAppStore()
                    } label: {
                        settingsRow(
                            icon: "star.fill",
                            title: "Avaliar na App Store"
                        )
                    }

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .presentationBackground(.ultraThinMaterial)
        .alert("Não foi possível abrir o link", isPresented: $showURLErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(urlErrorMessage)
        }
    }

    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        showToggle: Bool = false
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 17, design: .default))
                .foregroundColor(.white)

            Spacer()

            if showToggle {
                Toggle("", isOn: $hapticFeedbackEnabled)
                    .labelsHidden()
                    .tint(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private func rateOnAppStore() {
        HapticManager.shared.impact(style: .light)

        if let url = AppConfig.appStoreReviewURL {
            openExternalURL(url)
        }
    }

    private func openExternalURL(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            presentURLError()
            return
        }

        UIApplication.shared.open(url, options: [:]) { success in
            guard !success else { return }
            DispatchQueue.main.async {
                presentURLError()
            }
        }
    }

    private func presentURLError() {
        urlErrorMessage = Self.genericOpenErrorMessage
        showURLErrorAlert = true
        HapticManager.shared.notification(type: .error)
    }
}
