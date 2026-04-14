# Phase 8: Search Improvements

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Context

The search feature in `SearchView.swift` currently uses `localizedStandardContains` on the verse `text` field only. While Phase 2 added debouncing (300ms), background-thread fetching, and a loading spinner, several usability gaps remain:

- Only verse text is searched — users cannot search by book name or reference (e.g., "Gênesis 1:1").
- Results are sorted alphabetically by book name instead of canonical Bible order.
- There is no query highlighting in results, making it hard to spot why a verse matched.
- The result count is hidden — users don't know if they're seeing all results or a truncated set.
- Recent searches are not persisted, forcing users to retype common queries.
- The search field does not auto-focus when the view appears, requiring an extra tap.

## Tasks

### 8.1 Sort search results in canonical Bible order

In `SearchView.swift`, the `performSearch(query:)` function (line 190) sorts results by `bookName` using `.localizedStandard`, which produces alphabetical order (e.g., "Abdias" before "Gênesis"). Bible readers expect canonical order.

Replace the sort descriptors with a post-fetch sort using `BibleData.bookOrderMap`:

```swift
let results = try backgroundContext.fetch(descriptor)
let sorted = results.sorted { v1, v2 in
    let order1 = BibleData.bookOrderMap[v1.bookName] ?? 999
    let order2 = BibleData.bookOrderMap[v2.bookName] ?? 999
    if order1 != order2 { return order1 < order2 }
    if v1.chapterNumber != v2.chapterNumber { return v1.chapterNumber < v2.chapterNumber }
    return v1.verseNumber < v2.verseNumber
}
return sorted.map { $0.persistentModelID }
```

Remove the `sortBy` parameter from the `FetchDescriptor` since sorting is done in-memory after fetch.

### 8.2 Search by book name and reference

Currently only `verse.text` is searched via the `#Predicate`. Extend the predicate to also match against `verse.bookName`, so users can type a book name (e.g., "Gênesis") or partial reference (e.g., "Salmos") and see matching verses.

```swift
predicate: #Predicate { verse in
    verse.text.localizedStandardContains(trimmedQuery) ||
    verse.bookName.localizedStandardContains(trimmedQuery)
}
```

Note: `#Predicate` does not support string interpolation or complex reference parsing. For simple book name matching, the `||` approach is sufficient. Full reference parsing (e.g., "Gn 1:1") would require a separate code path outside the predicate.

### 8.3 Highlight matching text in search results

In the results list (line 144), verse text is displayed as plain `Text(verse.text)`. Add highlighting so the matched portion of the query stands out visually.

Create a helper function that builds an `AttributedString` (or uses `Text` concatenation) to highlight all occurrences of the search query within the verse text:

```swift
private func highlightedText(_ text: String, query: String) -> Text {
    guard !query.isEmpty else { return Text(text) }
    
    let lowercasedText = text.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    let lowercasedQuery = query.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    
    var result = Text("")
    var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
    var lastIndex = text.startIndex
    
    while let range = lowercasedText.range(of: lowercasedQuery, range: searchRange) {
        let originalRange = text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound))..<text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound))
        
        // Add text before match
        if lastIndex < originalRange.lowerBound {
            result = result + Text(text[lastIndex..<originalRange.lowerBound])
        }
        // Add highlighted match
        result = result + Text(text[originalRange])
            .foregroundColor(.yellow)
            .bold()
        
        lastIndex = originalRange.upperBound
        searchRange = range.upperBound..<lowercasedText.endIndex
    }
    
    // Add remaining text
    if lastIndex < text.endIndex {
        result = result + Text(text[lastIndex..<text.endIndex])
    }
    
    return result
}
```

Replace `Text(verse.text)` in the result row with `highlightedText(verse.text, query: searchText)`.

### 8.4 Show result count and truncation indicator

Users have no feedback about how many results were found or whether the 100-result limit was hit.

Add a result count header above the `ScrollView` in the results section:

```swift
HStack {
    Text(searchResults.count >= 100
        ? "Primeiros 100 resultados"
        : "\(searchResults.count) resultado\(searchResults.count == 1 ? "" : "s")")
        .font(.system(size: bodyFontSize * 0.8, design: .serif))
        .foregroundColor(.secondary)
    Spacer()
}
.padding(.horizontal, 16)
.padding(.top, 8)
```

This tells users when results are truncated and encourages them to refine their query.

### 8.5 Auto-focus the search field on appear

When `SearchView` opens, the user must tap the text field before typing. Auto-focus it using the `@FocusState` property wrapper:

```swift
@FocusState private var isSearchFieldFocused: Bool

// On the TextField:
TextField("Buscar versículos...", text: $searchText)
    .focused($isSearchFieldFocused)
    // ... existing modifiers

// Add .onAppear to the view:
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        isSearchFieldFocused = true
    }
}
```

The small delay (0.3s) ensures the view is fully presented before requesting focus, which avoids SwiftUI animation conflicts.

### 8.6 Persist recent searches

Store the last 10 unique search queries so users can quickly re-run common searches without retyping.

Add an `@AppStorage` property to persist searches as JSON:

```swift
@AppStorage("recentSearches") private var recentSearchesData: Data = Data()
```

Add helper functions to load, save, and manage the list:

```swift
private var recentSearches: [String] {
    (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
}

private func addToRecentSearches(_ query: String) {
    var searches = recentSearches
    searches.removeAll { $0.lowercased() == query.lowercased() }
    searches.insert(query, at: 0)
    if searches.count > 10 { searches = Array(searches.prefix(10)) }
    recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
}
```

Call `addToRecentSearches(trimmedQuery)` at the end of `performSearch` when results are found.

When `searchText` is empty, instead of showing only "Digite para buscar versículos", display the recent searches list (if any) with a "Recentes" header. Each item should be tappable — tapping it sets `searchText` to that query (which triggers a search via the existing `onChange`). Include a "Limpar" (Clear) button to erase the history.

### 8.7 Dismiss keyboard on scroll

When the user starts scrolling through results, the keyboard should dismiss automatically to reveal more screen space. Add `.scrollDismissesKeyboard(.interactively)` to the results `ScrollView`:

```swift
ScrollView {
    // ... results
}
.scrollDismissesKeyboard(.interactively)
```

This provides the standard iOS behavior where dragging the scroll view dismisses the keyboard smoothly.

## Validation

- Search results should appear in canonical Bible order (Gênesis → Apocalipse), not alphabetical.
- Typing a book name (e.g., "Salmos") should return verses from that book.
- The matched query text should be visually highlighted (yellow/bold) in each result.
- A result count should appear above results, showing "Primeiros 100 resultados" when truncated.
- The search field should auto-focus when the view opens, and the keyboard should appear immediately.
- After searching, the query should appear in the recent searches list on subsequent visits.
- Recent searches should be tappable to re-run the search, and clearable via a "Limpar" button.
- Scrolling through results should interactively dismiss the keyboard.
- All existing behaviors (debounce, background fetch, navigation to verse, loading spinner) should continue working.
