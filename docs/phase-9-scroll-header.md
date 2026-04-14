# Phase 9: Scroll-to-Hide Header

You are working on the `biblia-matos-soares` iOS app — a SwiftUI Bible reader using SwiftData for persistence.

## Context

The reading header (book selector, chapter selector, speaker button, search button) is always visible at the top of `ContentView`, reducing the available screen space for verse text. Most modern reading apps hide the header when the user scrolls down to maximize the reading area, and reveal it again when the user scrolls up. This is a common iOS pattern (e.g., Safari, Apple Books) that improves the immersive reading experience.

Currently in `ContentView.swift`, the header is rendered via `headerView(geometry:)` inside a `VStack(spacing: 0)` above the `ScrollView`. There is no scroll offset tracking or header visibility state.

## Tasks

### 9.1 Track scroll offset using a `PreferenceKey`

Create a `PreferenceKey` to report the scroll offset of the content `ScrollView`. Place a hidden anchor view at the top of the scroll content and use a `GeometryReader` inside a `background` modifier to capture its `minY` position relative to the scroll view's coordinate space.

```swift
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

Inside the `ScrollView`, add a background `GeometryReader` on the content to report the offset:

```swift
ScrollView {
    content
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geo.frame(in: .named("scroll")).minY
                )
            }
        )
}
.coordinateSpace(name: "scroll")
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
    handleScrollOffset(offset)
}
```

### 9.2 Compute scroll direction and toggle header visibility

Add state variables to track header visibility and the previous scroll offset:

```swift
@State private var isHeaderVisible: Bool = true
@State private var lastScrollOffset: CGFloat = 0
```

Implement a `handleScrollOffset(_:)` method that compares the current offset to the previous one. When the user scrolls down (offset decreasing) beyond a threshold, hide the header. When the user scrolls up (offset increasing), show it. Use a small dead-zone threshold (e.g., 10pt) to prevent flickering from minor scroll jitter.

```swift
private func handleScrollOffset(_ offset: CGFloat) {
    let delta = offset - lastScrollOffset
    
    // Scroll down — hide header
    if delta < -10 && isHeaderVisible {
        withAnimation(.easeOut(duration: 0.25)) {
            isHeaderVisible = false
        }
    }
    // Scroll up — show header
    else if delta > 10 && !isHeaderVisible {
        withAnimation(.easeOut(duration: 0.25)) {
            isHeaderVisible = true
        }
    }
    
    lastScrollOffset = offset
}
```

### 9.3 Animate the header in and out

Wrap the `headerView(geometry:)` call with a conditional based on `isHeaderVisible`. Use a slide + opacity transition so the header slides up out of view when hidden and back down when revealed:

```swift
VStack(spacing: 0) {
    if isHeaderVisible {
        headerView(geometry: geometry)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    ScrollViewReader { proxy in
        // ... existing scroll content
    }
}
```

### 9.4 Reset header visibility on chapter/book change

When the user changes books or chapters (via the picker sheets, swipe gesture, or navigation from search/notes/bookmarks), the header should always reappear. Add `isHeaderVisible = true` to the existing `.onChange(of: viewModel.selectedBook)` and `.onChange(of: viewModel.selectedChapter)` handlers.

### 9.5 Also hide floating action buttons when header is hidden

For a fully immersive reading mode, hide the floating action buttons at the bottom when the header is hidden. Apply the same visibility condition to the floating action buttons overlay:

```swift
if isHeaderVisible {
    VStack {
        Spacer()
        floatingActionButtons()
    }
    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
    .transition(.move(edge: .bottom).combined(with: .opacity))
}
```

This gives the user maximum reading area when scrolling through verses.

## Validation

- Scrolling down while reading should smoothly hide the header and floating buttons.
- Scrolling up should smoothly reveal the header and floating buttons.
- Small scrolls or jitter should not cause the header to flicker in and out.
- Changing books or chapters (via pickers, swipe, or navigation) should always show the header.
- The swipe-to-change-chapter gesture should continue working correctly.
- The header transition should feel smooth and natural (slide + fade, ~0.25s).
- All existing header functionality (book/chapter pickers, speaker, search) should work as before when the header is visible.
