# Phase 1: Code Health & Quick Wins

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Tasks

### 1.1 Remove duplicated `bookOrderMap` from `BibliaImporter`

In `biblia-matos-soares/BibliaImporter.swift`, delete the `bookOrderMap` instance property (lines 21-41) and replace any references to it with `BibleData.bookOrderMap` from `biblia-matos-soares/BibleData.swift`. The importer currently has its own copy of the exact same 73-entry dictionary — this is a maintenance hazard.

### 1.2 Extract `SettingsView` into its own file

`ContentView.swift` is ~830 lines and contains `SettingsView` (starting around line 683). Move `SettingsView` into a new file `biblia-matos-soares/SettingsView.swift`. Make sure to include all its private helper methods (`settingsRow`, `sendFeedback`, `rateOnAppStore`, `openExternalURL`, `presentURLError`) and the static error message property. Verify the file compiles by checking that all referenced types (`AppConfig`, `HapticManager`) are accessible.

### 1.3 Use `HapticManager` consistently in `HighlightedVersesView`

In `biblia-matos-soares/HighlightedVersesView.swift`, there are 3 places where `UIImpactFeedbackGenerator` is used directly instead of `HapticManager.shared`:

- Line 87-88: Back button — replace with `HapticManager.shared.impact(style: .light)`
- Line 152-153: "Abrir" context menu — replace with `HapticManager.shared.impact(style: .light)`
- Line 160-161: "Desmarcar" context menu — replace with `HapticManager.shared.impact(style: .medium)`

This ensures the user's haptic feedback toggle (in Settings) is respected everywhere. You can remove the `import UIKit` if it's no longer needed after the change (check if anything else in the file uses UIKit types).

### 1.4 Add SwiftData indexes on `BibleVerse`

In `biblia-matos-soares/BibleVerse.swift`, add index attributes to optimize the queries that run on every chapter render. The main query filters by `bookName` and `chapterNumber` and sorts by `verseNumber`. Use SwiftData's `#Index` macro or `@Attribute` annotations to add appropriate indexes. Refer to Apple's SwiftData documentation for the correct syntax for the iOS version target.

### 1.5 Replace placeholder feedback URL

In `ContentView.swift` (or `SettingsView.swift` after task 1.2), the `sendFeedback()` function uses `"https://forms.gle/YOUR_FORM_ID"`. Either:
- Ask the project owner for the real Google Form URL and replace it, or
- Remove the "Enviar feedback" button entirely until a real URL is available, to avoid sending users to a broken link.

## Validation

- Build the project in Xcode to verify all files compile.
- Verify that `BibliaImporter` no longer has its own `bookOrderMap` and the import still works.
- Verify that haptic feedback in `HighlightedVersesView` respects the Settings toggle.
