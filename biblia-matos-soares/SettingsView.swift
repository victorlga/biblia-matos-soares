import SwiftUI
import SwiftData
import UIKit
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Settings View
struct SettingsView: View {
    private static var genericOpenErrorMessage: String { "Desculpe, não foi possível abrir o link." }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("fontSize") private var fontSize: Double = 17.0
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
                    // Font size slider
                    fontSizeRow()

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
                                title: "Melhorar voz de leitura"
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
                            title: "Exportar notas e marcações"
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
                            title: "Importar notas e marcações"
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
        .alert("Melhorar voz de leitura", isPresented: $showVoiceHintAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Para uma voz de leitura mais natural, vá em Ajustes > Acessibilidade > Conteúdo Falado > Vozes > Português (Brasil) e baixe a voz aprimorada ou premium.")
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
                importResultMessage = String(format: "Erro ao selecionar arquivo: %@", error.localizedDescription)
                showImportResultAlert = true
            }
        }
        .alert("Notas duplicadas", isPresented: $showImportConflictAlert) {
            Button("Manter existentes") {
                performImport(resolution: .keepExisting)
            }
            Button("Sobrescrever") {
                performImport(resolution: .overwrite)
            }
            Button("Anexar") {
                performImport(resolution: .append)
            }
            Button("Cancelar", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("Se já existir uma nota para o mesmo versículo, o que deseja fazer?")
        }
        .alert("Importação", isPresented: $showImportResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importResultMessage)
        }
    }

    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String
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

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func fontSizeRow() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 28)

                Text("Tamanho da fonte")
                    .font(.system(size: 17, design: .default))
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 12) {
                Text("A")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))

                Slider(
                    value: $fontSize,
                    in: 15...31,
                    step: 2,
                    onEditingChanged: { editing in
                        if !editing {
                            HapticManager.shared.impact(style: .light)
                        }
                    }
                )
                .accentColor(.white)

                Text("A")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func speechRateRow() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 28)

                Text("Velocidade de leitura")
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
            importResultMessage = "Não foi possível acessar o arquivo."
            showImportResultAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        if let result = DataExportImportManager.importData(from: url, context: modelContext, noteConflict: resolution) {
            importResultMessage = String(format: "Importação concluída: %d nota(s) e %d marcação(ões) importadas.", result.notes, result.highlights)
            HapticManager.shared.notification(type: .success)
        } else {
            importResultMessage = "Erro ao importar os dados. Verifique se o arquivo é válido."
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
