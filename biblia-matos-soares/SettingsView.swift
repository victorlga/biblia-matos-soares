import SwiftUI
import SwiftData
import UIKit
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Settings View
struct SettingsView: View {
    private static var genericOpenErrorMessage: String { String(localized: "settings.url_error") }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var hapticFeedbackEnabled: Bool
    @AppStorage("speechRate") private var speechRate: Double = 0.48
    @State private var showURLErrorAlert = false
    @State private var urlErrorMessage = ""
    @State private var showVoiceHintAlert = false
    @State private var showImportPicker = false
    @State private var showImportConflictAlert = false
    @State private var pendingImportURL: URL?
    @State private var showImportResultAlert = false
    @State private var importResultMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                    // Haptic feedback toggle
                    settingsRow(
                        icon: "hand.tap.fill",
                        title: String(localized: "settings.haptic_feedback"),
                        showToggle: true
                    )

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Speech rate slider
                    speechRateRow()

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Voice quality hint (only when default quality)
                    if SpeechHelper.shouldShowVoiceQualityHint() {
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showVoiceHintAlert = true
                        } label: {
                            settingsRow(
                                icon: "speaker.wave.3.fill",
                                title: String(localized: "settings.improve_voice")
                            )
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                    }

                    // Export data
                    Button {
                        HapticManager.shared.impact(style: .light)
                        exportData()
                    } label: {
                        settingsRow(
                            icon: "square.and.arrow.up",
                            title: String(localized: "settings.export")
                        )
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Import data
                    Button {
                        HapticManager.shared.impact(style: .light)
                        showImportPicker = true
                    } label: {
                        settingsRow(
                            icon: "square.and.arrow.down",
                            title: String(localized: "settings.import")
                        )
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Rate on App Store
                    Button {
                        rateOnAppStore()
                    } label: {
                        settingsRow(
                            icon: "star.fill",
                            title: String(localized: "settings.rate_app")
                        )
                    }

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(String(localized: "settings.title"))
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
        .alert(String(localized: "settings.url_error_title"), isPresented: $showURLErrorAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(urlErrorMessage)
        }
        .alert(String(localized: "settings.improve_voice"), isPresented: $showVoiceHintAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.improve_voice_hint"))
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    pendingImportURL = url
                    showImportConflictAlert = true
                }
            case .failure(let error):
                importResultMessage = String(format: String(localized: "import.file_select_error"), error.localizedDescription)
                showImportResultAlert = true
            }
        }
        .alert(String(localized: "import.duplicate_title"), isPresented: $showImportConflictAlert) {
            Button(String(localized: "import.keep_existing")) {
                performImport(resolution: .keepExisting)
            }
            Button(String(localized: "import.overwrite")) {
                performImport(resolution: .overwrite)
            }
            Button(String(localized: "import.append")) {
                performImport(resolution: .append)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text(String(localized: "import.duplicate_message"))
        }
        .alert(String(localized: "import.title"), isPresented: $showImportResultAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(importResultMessage)
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

    @ViewBuilder
    private func speechRateRow() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 28)

                Text(String(localized: "settings.speech_rate"))
                    .font(.system(size: 17, design: .default))
                    .foregroundColor(.white)

                Spacer()
            }

            Slider(
                value: $speechRate,
                in: 0.3...0.6,
                onEditingChanged: { editing in
                    if !editing {
                        HapticManager.shared.impact(style: .light)
                    }
                }
            )
            .accentColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func exportData() {
        if let url = DataExportImportManager.exportData(context: modelContext) {
            DataExportImportManager.presentShareSheet(for: url)
        }
    }

    private func performImport(resolution: ImportConflictResolution) {
        guard let url = pendingImportURL else { return }
        defer { pendingImportURL = nil }

        guard url.startAccessingSecurityScopedResource() else {
            importResultMessage = String(localized: "import.file_error")
            showImportResultAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        if let result = DataExportImportManager.importData(from: url, context: modelContext, noteConflict: resolution) {
            importResultMessage = String(format: String(localized: "import.success"), result.notes, result.highlights)
            HapticManager.shared.notification(type: .success)
        } else {
            importResultMessage = String(localized: "import.error")
            HapticManager.shared.notification(type: .error)
        }
        showImportResultAlert = true
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
