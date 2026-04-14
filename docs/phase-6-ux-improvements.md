# Phase 6: UX Improvements

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Tasks

### 6.1 Book selector should scroll to the current book

In `ContentView.swift`, the book selector in `headerView(geometry:)` (around line 388) uses a `Menu` with a `ForEach` over `BibleData.orderedBookNames`. When the user taps the dropdown, the list always starts at the top (Gênesis), regardless of which book they are currently reading. This forces unnecessary scrolling — for example, if reading Apocalipse (book 73), the user must scroll through all 72 preceding books.

Replace the `Menu`-based book selector with a custom presentation (e.g., a `.sheet` containing a `ScrollViewReader` + `List` or `ScrollView`) that:
- Displays all 73 books in canonical order.
- On appear, uses `ScrollViewReader.scrollTo(selectedBook, anchor: .center)` to auto-scroll to the currently selected book.
- Highlights the currently selected book visually (e.g., accent color, checkmark, or bold text).
- Dismisses on selection and updates `selectedBook`.
- Follows the app's dark theme, serif font, and existing visual conventions.
- Adds haptic feedback on selection via `HapticManager.shared.impact(style: .light)`.

The state for presenting the sheet can be a simple `@State private var showBookPicker: Bool = false`. The header button label should remain the same (`selectedBook` text + chevron.down icon).

### 6.2 Chapter selector should scroll to the current chapter

Similarly, the chapter selector (around line 413) uses a `Menu` with a `ForEach` from 1 to the book's chapter count. If the user is on chapter 50 of Gênesis and wants to jump to chapter 55, they must scroll from chapter 1 all the way to 55.

Replace the `Menu`-based chapter selector with a custom presentation that:
- Displays chapters in a grid layout (`LazyVGrid` with adaptive columns, minimum width ~56pt) for faster visual scanning — chapters are just numbers, so a grid is more space-efficient than a list.
- On appear, uses `ScrollViewReader.scrollTo(selectedChapter, anchor: .center)` to auto-scroll to the currently selected chapter.
- Highlights the currently selected chapter (e.g., accent background color or ring).
- Dismisses on selection and updates `selectedChapter`.
- Follows the app's dark theme and visual conventions.
- Adds haptic feedback on selection via `HapticManager.shared.impact(style: .light)`.

Present this in a `.sheet` with `presentationDetents` appropriate to the chapter count — use a medium detent for books with few chapters and a larger detent for books like Salmos (150 chapters).

### 6.3 Preserve chapter when switching between books with compatible chapter counts

In `ContentView.swift`, the `.onChange(of: selectedBook)` handler (around line 174) always resets `selectedChapter = 1` when the user changes books. This is unnecessarily disruptive when the new book has enough chapters to keep the current selection.

Change the logic to:
- If the new book has at least as many chapters as the current `selectedChapter`, keep `selectedChapter` unchanged.
- If the new book has fewer chapters, set `selectedChapter` to the new book's last chapter (or 1, either is acceptable — last chapter may feel more natural since the user was deep into the previous book).

```swift
.onChange(of: selectedBook) { _, newBook in
    if speechSynthesizer.isSpeaking {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    let maxChapter = BibleData.numberOfChapters(forBook: newBook) ?? 1
    withAnimation(.easeOut(duration: 0.3)) {
        if selectedChapter > maxChapter {
            selectedChapter = 1
        }
        proxy.scrollTo(1, anchor: .top)
        storedBook = newBook
        storedChapter = selectedChapter
        updateReadingHistory()
    }
}
```

## Validation

- Opening the book selector should auto-scroll to the current book — the user should see it centered or near-center without manual scrolling.
- Opening the chapter selector should auto-scroll to the current chapter — the user should see it highlighted and centered.
- Switching from a book with 50 chapters while on chapter 30 to another book with 40+ chapters should preserve chapter 30.
- Switching from a book with 50 chapters while on chapter 50 to a book with only 4 chapters should reset to chapter 1 (or last chapter).
- Both selectors should respect the app's dark theme, serif font, and haptic feedback settings.
- The overall look and feel should match the existing header design (rounded rectangle background, system gray fill, etc.).
