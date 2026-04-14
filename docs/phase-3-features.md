# Phase 3: Feature Enhancements

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Tasks

### 3.1 Surface reading history

The app already tracks the last 10 visited book+chapter combinations in `@AppStorage("readingHistory")` (see `updateReadingHistory()` in `ContentView.swift`, around line 642). The data is stored as a JSON-encoded `[String]` where each entry is `"BookName|ChapterNumber"`.

Create a "Recentes" (Recent) section accessible from the main screen:
- Add a new floating action button (clock icon `clock.arrow.circlepath`) or integrate into the existing navigation.
- Create a `ReadingHistoryView` that decodes `readingHistoryData`, displays entries as a list ("Gênesis, Cap. 1", "São Mateus, Cap. 5", etc.), and navigates to the selected book+chapter on tap.
- Follow the same dark theme, serif font, and layout conventions as `NotesView` and `HighlightedVersesView`.

### 3.2 Show note indicator on verses

Users currently have no way to tell which verses have notes while reading a chapter. Add a visual indicator:
- In `ContentView.swift`'s verse rendering (`versesWithContinuousHighlight`, around line 235), query for `VerseNote` entries matching the current book+chapter.
- For verses that have at least one note, show a small icon (e.g., `note.text` SF Symbol) next to the verse number or text.
- Keep it subtle — use `.secondary` color and a small font size so it doesn't distract from reading.
- Tapping the indicator could open the existing note in `NoteEditorView` for editing.

### 3.3 Verse-level navigation from search and bookmarks

Currently, `SearchView` and `HighlightedVersesView` use `onNavigateToVerse: ((String, Int) -> Void)?` which only passes `bookName` and `chapterNumber`. The user lands at the top of the chapter, not at the specific verse.

Extend the callback to include verse number:
- Change the signature to `((String, Int, Int) -> Void)?` (bookName, chapterNumber, verseNumber).
- In `ContentView`, after setting `selectedBook` and `selectedChapter`, use `ScrollViewReader.scrollTo(verseNumber, anchor: .top)` to scroll to the specific verse.
- The verse IDs are already set via `.id(verse.verseNumber)` (line 260 in ContentView), so `scrollTo` should work directly.

### 3.4 Add a "Daily Verse" feature

Show a verse of the day on a dedicated screen or as a card on the main view:
- Create a `DailyVerseView` or a collapsible card at the top of `ContentView`.
- Use a deterministic algorithm based on the current date (e.g., day-of-year modulo total verse count) to select a verse from SwiftData.
- Display the verse text with its reference, styled distinctively (e.g., larger font, subtle background).
- Include a share button and a bookmark button.
- Optionally, allow the user to navigate to the verse's chapter by tapping it.

### 3.5 Restore and improve the "Copy" action

In `ContentView.swift`, the "Copiar Referência" context menu option is commented out (lines 275-279). Restore it and improve it:
- Uncomment the button.
- Change the copy behavior to include both the reference AND the verse text: `"Gênesis 1:1 - No principio criou Deus o céu e a terra."` (same format used by the share function).
- Keep the long-press on verse number for copying just the reference (this already works via `copyVerseReference`).
- Add haptic feedback using `HapticManager.shared`.

## Validation

- Reading history should show the last 10 visited chapters and navigate correctly.
- Verses with notes should display a subtle indicator in the reading view.
- Tapping a search result or bookmark should scroll to the exact verse, not just the chapter.
- Daily verse should change each day and be shareable.
- Copy should place the full verse reference + text on the clipboard.
