# Phase 4: Architecture & Scalability

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Tasks

### 4.1 Introduce a ViewModel layer for ContentView

`ContentView.swift` currently contains ~680 lines mixing UI layout, data fetching, navigation logic, text-to-speech, clipboard operations, and reading history management. Extract the non-UI logic into a `ContentViewModel`:

- Create `biblia-matos-soares/ContentViewModel.swift` as an `@Observable` class (or `ObservableObject`).
- Move into it:
  - `selectedBook` and `selectedChapter` state + persistence logic (`storedBook`, `storedChapter`).
  - `verses` computed property (SwiftData fetch).
  - `goToNextChapter()` and `goToPreviousChapter()` navigation.
  - `readCurrentChapter()` (TTS logic).
  - `toggleHighlight(for:)`, `copyVerseReference(_:)`, `shareVerse(_:)`.
  - `updateReadingHistory()` and `readingHistoryData`.
  - `groupConsecutiveHighlightedVerses(_:)`.
- `ContentView` should only handle layout, gestures, and binding to the ViewModel.
- Keep `@AppStorage` properties in the ViewModel (they work outside of views).

### 4.2 Create a SwiftData relationship between `BibleVerse` and `VerseNote`

Currently, `VerseNote` references its verse by storing `bookName`, `chapterNumber`, and `verseNumber` as independent fields. This is fragile and makes queries harder.

Refactor to use a SwiftData relationship:
- Add a `@Relationship` property to `BibleVerse`: `var notes: [VerseNote]`
- Add an inverse `@Relationship` on `VerseNote`: `var verse: BibleVerse?`
- Remove the redundant `bookName`, `chapterNumber`, `verseNumber` fields from `VerseNote` (or keep them as computed properties that delegate to `verse`).
- Update `NoteEditorView.saveNote()` to set the relationship instead of copying fields.
- Update `NotesView` queries to navigate via the relationship.
- Handle the SwiftData migration if there is existing user data (use a `VersionedSchema` and `SchemaMigrationPlan`).

### 4.3 Add unit tests for core logic

Create a test target and write unit tests for the pure-logic components:

**`BibleDataTests`**:
- `orderedBookNames` has exactly 73 entries.
- First book is "Gênesis", last is "Apocalipse".
- `numberOfChapters(forBook:)` returns correct values for known books and `nil` for unknown.
- `bookOrderMap` and `bookChapterCounts` have the same keys.

**`BibleImporterTests`**:
- Import into an in-memory SwiftData container succeeds.
- Correct total verse count after import.
- `hasImportedData()` returns `false` before import, `true` after.
- Double-import does not duplicate data (if you add that guard).

**`ContentViewLogicTests`** (test the ViewModel after 4.1):
- `goToNextChapter()` from last chapter of a book advances to the next book.
- `goToNextChapter()` from Apocalipse wraps to Gênesis 1.
- `goToPreviousChapter()` from chapter 1 goes to last chapter of previous book.
- `goToPreviousChapter()` from Gênesis 1 wraps to Apocalipse's last chapter.
- `groupConsecutiveHighlightedVerses` correctly groups alternating highlight patterns.

### 4.4 Set up a GitHub Actions CI pipeline

Create `.github/workflows/build.yml`:
- Trigger on push and pull requests to `main`.
- Use a macOS runner (`macos-latest`).
- Steps: checkout, select Xcode version, build the project (`xcodebuild build`), run tests (`xcodebuild test`).
- Use the correct scheme name from the `.xcodeproj` (check `xcshareddata/xcschemes/`).
- Cache Swift Package Manager dependencies if any are added in the future.

## Validation

- The ViewModel refactor should not change any user-facing behavior. All existing interactions must work identically.
- The relationship migration must handle existing users who have notes — no data loss.
- All unit tests must pass in CI.
- The GitHub Actions workflow should build and test successfully on every PR.
