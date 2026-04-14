# Phase 7: Text-to-Speech Voice Improvement

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Context

The current reading feature in `ContentView.swift` uses `AVSpeechSynthesizer` with `AVSpeechSynthesisVoice(language: "pt-BR")`, which always selects the default/compact quality voice (likely "Luciana compact"). This is the lowest quality tier available on iOS and sounds noticeably robotic. Additionally, the entire chapter is spoken as a single utterance with no rate/pitch tuning and no pauses between verses.

Apple's `AVSpeechSynthesisVoice` supports three quality tiers — `default` (1), `enhanced` (2), and `premium` (3) — where enhanced and premium voices must be downloaded by the user via iOS Settings > Accessibility > Spoken Content > Voices. The app can programmatically select the best available voice on the device.

## Tasks

### 7.1 Select the best available pt-BR voice

In `ContentView.swift`, the `readCurrentChapter()` function (around line 608) creates a voice with `AVSpeechSynthesisVoice(language: "pt-BR")`, which always returns the compact/default voice regardless of what the user has downloaded.

Add a helper function that iterates through `AVSpeechSynthesisVoice.speechVoices()`, filters for `pt-BR` voices, and selects the one with the highest `.quality` (premium > enhanced > default). Fall back to `AVSpeechSynthesisVoice(language: "pt-BR")` if no voices are found.

```swift
private func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
    let ptBRVoices = AVSpeechSynthesisVoice.speechVoices()
        .filter { $0.language == "pt-BR" }
        .sorted { $0.quality.rawValue > $1.quality.rawValue }
    return ptBRVoices.first ?? AVSpeechSynthesisVoice(language: "pt-BR")
}
```

Update `readCurrentChapter()` to use `bestAvailableVoice()` instead of `AVSpeechSynthesisVoice(language: "pt-BR")`.

### 7.2 Tune utterance parameters for more natural reading

In `readCurrentChapter()`, the `AVSpeechUtterance` is created with all default parameters. Add rate and pitch customizations to make the speech sound more natural:

```swift
utterance.rate = 0.48              // Slightly slower than default (0.5) for comfortable Bible reading
utterance.pitchMultiplier = 1.05   // Slightly higher pitch for warmth
```

These values should be tested and adjusted if needed. The default `rate` is `AVSpeechUtteranceDefaultSpeechRate` (0.5) and range is 0.0–1.0. The default `pitchMultiplier` is 1.0 and range is 0.5–2.0.

### 7.3 Break chapter into per-verse utterances with pauses

Currently, all verses are joined into a single string and spoken as one utterance. This produces unnatural phrasing with no breathing room between verses.

Refactor `readCurrentChapter()` to enqueue one `AVSpeechUtterance` per verse, each with a small `preUtteranceDelay` to create natural pauses between verses:

```swift
private func readCurrentChapter() {
    let voice = bestAvailableVoice()
    for verse in verses {
        let utterance = AVSpeechUtterance(string: verse.text)
        utterance.voice = voice
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.3
        speechSynthesizer.speak(utterance)
    }
}
```

`AVSpeechSynthesizer.speak()` enqueues utterances, so calling it in a loop is the correct approach — each utterance will play after the previous one finishes (plus the `preUtteranceDelay`).

Verify that `speechSynthesizer.stopSpeaking(at: .immediate)` still correctly stops all enqueued utterances (it should — `stopSpeaking` clears the queue).

### 7.4 Add a voice quality hint in Settings

In `SettingsView`, add an informational row that guides users to download better voices. This should appear below the existing settings rows:

- Icon: `speaker.wave.3.fill`
- Title: "Melhorar voz de leitura"
- Tapping it should show an alert or a small explanation telling the user to go to **Ajustes > Acessibilidade > Conteúdo Falado > Vozes > Português (Brasil)** and download the enhanced or premium voice for better reading quality.
- This row should only be visible if the best available pt-BR voice is of `default` quality (i.e., no enhanced/premium voice is installed). Use the same `bestAvailableVoice()` logic to check.

### 7.5 (Optional) Add speech rate control to Settings

Consider adding a slider in `SettingsView` (similar to the existing font size slider pattern) that lets the user adjust the reading speed:

- Store the value with `@AppStorage("speechRate")` with a default of `0.48`.
- Range: 0.3 (slow) to 0.6 (fast), with 0.48 as default.
- Use this stored value in the utterance `rate` parameter.
- Icon: `gauge.with.dots.needle.33percent` or similar.
- Label: "Velocidade de leitura".

## Validation

- The reading feature should automatically use the highest-quality pt-BR voice available on the device.
- If the user has downloaded an enhanced or premium Portuguese voice via iOS Settings, the app should use it without any manual configuration.
- Speech should have natural pauses between verses instead of running all text together.
- The `stopSpeaking` functionality should still work correctly, stopping all enqueued verse utterances immediately.
- The voice quality hint should only appear in Settings when the user has not downloaded a better voice.
- All existing behaviors (stop on swipe, stop on book/chapter change) should continue to work with the per-verse utterance approach.
