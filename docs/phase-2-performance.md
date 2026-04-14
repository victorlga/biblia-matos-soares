# Phase 2: Performance & Reliability

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Tasks

### 2.1 Move search to a background context

In `biblia-matos-soares/SearchView.swift`, the `performSearch(query:)` function (around line 160) runs a synchronous `FetchDescriptor` query on the main thread. This can freeze the UI on older devices, especially since the Bible has ~30k verses.

Refactor the search to run on a background thread:
- Create a `ModelActor` or use `Task.detached` with a background `ModelContext`.
- Update `searchResults` on the main thread after the background fetch completes.
- Consider cancelling in-flight searches when a new query arrives (use `Task` cancellation).

### 2.2 Debounce search input

Still in `SearchView.swift`, the `.onChange(of: searchText)` handler (line 80) calls `performSearch` on every keystroke. Add a ~300ms debounce so the query only runs after the user pauses typing.

You can achieve this with a `Task` + `Task.sleep(nanoseconds:)` pattern, cancelling the previous task on each keystroke:
```swift
@State private var searchTask: Task<Void, Never>?

// In onChange:
searchTask?.cancel()
searchTask = Task {
    try? await Task.sleep(nanoseconds: 300_000_000)
    guard !Task.isCancelled else { return }
    performSearch(query: newValue)
}
```

### 2.3 Batch the Bible import

In `biblia-matos-soares/BibliaImporter.swift`, the `importBible()` function (line 43) inserts all ~30k verses in a single transaction and saves once. This can spike memory on first launch.

Refactor to batch the import per book:
- After processing each book's chapters/verses, call `context.save()`.
- Optionally wrap each book's processing in an `autoreleasepool { }` to allow ARC to free intermediate objects.
- Log progress (e.g., "Imported Gênesis (1/73)") for debugging.

### 2.4 Add a loading state for first launch

In `biblia-matos-soares/biblia_matos_soaresApp.swift`, the `.task` modifier (line 80) runs the import asynchronously, but `ContentView` renders immediately and shows "Selecione um livro e um capítulo" because there are no verses yet.

Use the existing `ImportStatus.isImportComplete` flag to show a loading indicator:
- In `ContentView.swift`, check `importStatus.isImportComplete` before rendering verses.
- While `false`, show a centered `ProgressView` with a message like "Carregando a Bíblia..." in serif font to match the app's style.
- The `refreshTrigger` logic that already exists (line 205-210) handles the transition when import completes.

## Validation

- Test search with rapid typing — the UI should remain responsive.
- Test first launch — a loading indicator should appear until import completes.
- Monitor memory usage during import (Xcode Instruments) to verify batching helps.
