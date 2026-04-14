import AVFoundation

/// Shared helper for Text-to-Speech voice selection.
/// Used by both ContentView (for reading) and SettingsView (for voice quality hint).
enum SpeechHelper {

    /// Returns the highest-quality pt-BR voice available on the device.
    /// Priority: premium > enhanced > default.
    /// Falls back to `AVSpeechSynthesisVoice(language: "pt-BR")` if no voices are found.
    static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let ptBRVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "pt-BR" }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
        return ptBRVoices.first ?? AVSpeechSynthesisVoice(language: "pt-BR")
    }

    /// Returns `true` when the best available pt-BR voice is only `default` quality,
    /// meaning the user has not downloaded an enhanced or premium voice.
    static func shouldShowVoiceQualityHint() -> Bool {
        guard let voice = bestAvailableVoice() else { return true }
        return voice.quality == .default
    }
}
