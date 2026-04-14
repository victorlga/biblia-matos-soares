# Phase 5: Polish & Growth

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Tasks

### 5.1 Reading plan / progress tracker

Add a feature that tracks which chapters the user has read and shows overall Bible reading progress:

- Create a new SwiftData model `ReadingProgress` with fields: `bookName: String`, `chapterNumber: Int`, `completedAt: Date`.
- Mark a chapter as "read" automatically when the user finishes scrolling to the bottom, or provide a manual "Mark as read" button.
- Create a `ReadingProgressView` showing:
  - Overall progress bar (e.g., "245 / 1,189 chapters read").
  - Per-book progress (collapsible sections showing which chapters are read).
  - A streak counter (consecutive days with at least one chapter read).
- Add a floating action button or tab to access the progress view.
- Follow the app's dark theme, serif font, and Portuguese language conventions.

### 5.2 Multiple highlight colors

Currently, `isHighlighted` is a simple Boolean. Extend it to support multiple colors:

- Replace `isHighlighted: Bool` on `BibleVerse` with `highlightColor: String?` (where `nil` = not highlighted, and values like `"yellow"`, `"green"`, `"blue"`, `"pink"` represent colors).
- Handle the SwiftData migration from the old Boolean field using `VersionedSchema` and `SchemaMigrationPlan`. Map `true` to `"yellow"` and `false` to `nil`.
- Update the context menu to show a color picker (row of colored circles) instead of a simple toggle.
- Update `versesWithContinuousHighlight` in `ContentView` to group by color (verses with the same color are grouped together).
- Update `HighlightedVersesView` to show the highlight color for each verse and optionally filter by color.
- Color palette: yellow (`Color.yellow.opacity(0.3)`), green (`Color.green.opacity(0.3)`), blue (`Color.blue.opacity(0.3)`), pink (`Color.pink.opacity(0.3)`).

### 5.3 Export/import notes and highlights

Allow users to back up and restore their personal data:

- **Export**: Create a function that serializes all `VerseNote` entries and highlighted `BibleVerse` entries into a JSON file. Include metadata (export date, app version, verse count). Present a share sheet with the JSON file.
- **Import**: Allow users to pick a JSON file and merge the data into their existing database. Handle conflicts (e.g., if a verse is already highlighted, keep it; if a note exists for the same verse, ask whether to overwrite or append).
- Add Export/Import buttons to `SettingsView`.
- Future consideration: iCloud sync using `CloudKit` + SwiftData's built-in cloud sync support. This is a larger undertaking but the export/import feature provides an immediate backup solution.

### 5.4 Localization framework

Extract all hardcoded Portuguese strings into proper localization files:

- Create `Localizable.strings` (or use the modern `String Catalog` `.xcstrings` format) for `pt-BR`.
- Replace all hardcoded strings in views with `String(localized:)` or `NSLocalizedString`.
- Key areas with hardcoded strings:
  - `ContentView`: "Selecione um livro e um capítulo", "Cap.", etc.
  - `SearchView`: "Buscar", "Buscar versiculos...", "Nenhum resultado encontrado", etc.
  - `NotesView`: "Notas", "Nenhuma nota criada...", "Versículo", etc.
  - `HighlightedVersesView`: "Voltar", "Nenhum versículo marcado...", etc.
  - `OnboardingView`: All feature titles and descriptions.
  - `SettingsView`: "Configurações", "Feedback tátil", "Enviar feedback", etc.
  - Context menus: "Marcar", "Desmarcar", "Adicionar Nota", "Compartilhar", etc.
- Do NOT translate the Bible text itself — only UI strings.
- Optionally add an English (`en`) localization as a secondary language.

### 5.5 iPad optimization with split-view layout

The app already checks `horizontalSizeClass` but doesn't significantly adapt for iPad:

- On `.regular` horizontal size class (iPad), implement a `NavigationSplitView`:
  - **Sidebar**: List of books (grouped by Old Testament / New Testament).
  - **Detail**: The current chapter reading view.
- Keep the current single-column layout for `.compact` (iPhone).
- Adjust the floating action buttons positioning for the larger iPad screen.
- Test on iPad simulator in both portrait and landscape orientations.
- Consider supporting Stage Manager / multi-window on iPadOS.

## Validation

- Reading progress should persist across app launches and accurately reflect chapters read.
- Highlight colors should migrate cleanly from the old Boolean field without data loss.
- Exported JSON should be importable on a fresh install, restoring all notes and highlights.
- All UI strings should come from localization files; no hardcoded Portuguese in Swift source.
- iPad should show a split-view layout in landscape and adapt gracefully to all orientations.
