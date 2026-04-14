import SwiftUI
import SwiftData
import AVFoundation
import UIKit

// View extension for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("fontSize") private var fontSize: Double = 17.0
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("speechRate") private var speechRate: Double = 0.48

    @State private var viewModel = ContentViewModel()

    @State private var showOnboarding: Bool = false
    @State private var showFontSizeSlider: Bool = false
    @State private var showSettings: Bool = false
    @State private var showReadingHistory: Bool = false
    @State private var showDailyVerse: Bool = false
    @State private var showBookPicker: Bool = false
    @State private var showChapterPicker: Bool = false

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentTranslationDirection: HorizontalTransitionDirection = .none

    @State private var noteEditorMode: NoteEditorMode?
    @State private var scrollToVerse: Int?
    @State private var refreshTrigger = UUID()

    @EnvironmentObject private var importStatus: ImportStatus

    enum NoteEditorMode: Identifiable {
        case newNote(BibleVerse)
        case editNote(VerseNote)

        var id: String {
            switch self {
            case .newNote(let verse): return "new-\(verse.id)"
            case .editNote(let note): return "edit-\(note.id)"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var verseFontSize: CGFloat {
        CGFloat(fontSize)
    }

    private var verseNumberFontSize: CGFloat {
        verseFontSize
    }

    private var headerFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 20
        case .regular: return 28
        default: return 20
        }
    }

    private var verses: [BibleVerse] {
        viewModel.fetchVerses(context: modelContext)
    }

    enum HorizontalTransitionDirection {
        case left
        case right
        case none
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        headerView(geometry: geometry)

                        ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: geometry.size.height * 0.02) {
                                        if !importStatus.isImportComplete {
                                            VStack(spacing: 16) {
                                                Spacer()
                                                ProgressView()
                                                    .tint(.gray)
                                                Text("Carregando a Bíblia...")
                                                    .font(.system(size: headerFontSize, weight: .regular, design: .serif))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                                        } else if verses.isEmpty {
                                            Text("Selecione um livro e um capítulo.")
                                                        .font(.system(size: headerFontSize, weight: .regular, design: .serif))
                                                        .foregroundColor(.gray)
                                                        .multilineTextAlignment(.center)
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                                        } else {
                                        // Renderizar versículos com destaque contínuo
                                        versesWithContinuousHighlight(geometry: geometry)
                                    }

                                    Color.clear
                                        .frame(height: 120)
                                }
                                .padding(.top, geometry.size.height * 0.02)
                                .transition(currentTransition)
                            }
                            .id(refreshTrigger)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if !isDragging {
                                            dragOffset = gesture.translation
                                            isDragging = true
                                        }
                                    }
                                    .onEnded { gesture in
                                        let horizontalTranslation = gesture.translation.width
                                        let verticalTranslation = gesture.translation.height

                                        if abs(horizontalTranslation) > abs(verticalTranslation) {
                                            if viewModel.speechSynthesizer.isSpeaking {
                                                viewModel.speechSynthesizer.stopSpeaking(at: .immediate)
                                            }

                                            if horizontalTranslation > 50 {
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    currentTranslationDirection = .right
                                                    viewModel.goToPreviousChapter()
                                                }
                                            } else if horizontalTranslation < -50 {
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    currentTranslationDirection = .left
                                                    viewModel.goToNextChapter()
                                                }
                                            }
                                        }
                                        isDragging = false
                                        dragOffset = .zero
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            currentTranslationDirection = .none
                                        }
                                    }
                            )
                                            .onChange(of: viewModel.selectedBook) { _, _ in
                                                if viewModel.speechSynthesizer.isSpeaking {
                                                    viewModel.speechSynthesizer.stopSpeaking(at: .immediate)
                                                }
                                                let maxChapter = BibleData.numberOfChapters(forBook: viewModel.selectedBook) ?? 1
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    // Only reset chapter if this isn't a programmatic
                                                    // navigation that already set the target chapter
                                                    // (e.g., goToPreviousChapter crossing book boundaries).
                                                    if viewModel.suppressChapterReset {
                                                        viewModel.suppressChapterReset = false
                                                    } else if viewModel.selectedChapter > maxChapter {
                                                        viewModel.selectedChapter = 1
                                                    }
                                                    let targetVerse = scrollToVerse ?? 1
                                                    scrollToVerse = nil
                                                    proxy.scrollTo(targetVerse, anchor: .top)
                                                    viewModel.syncBookToStorage()
                                                }
                                            }
                            .onChange(of: viewModel.selectedChapter) { _, _ in
                                if viewModel.speechSynthesizer.isSpeaking {
                                    viewModel.speechSynthesizer.stopSpeaking(at: .immediate)
                                }
                                withAnimation(.easeOut(duration: 0.3)) {
                                    let targetVerse = scrollToVerse ?? 1
                                    scrollToVerse = nil
                                    proxy.scrollTo(targetVerse, anchor: .top)
                                    viewModel.syncChapterToStorage()
                                }
                            }
                        }
                    }

                    // Floating action buttons at the bottom
                    VStack {
                        Spacer()
                        floatingActionButtons()
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                }
                .preferredColorScheme(.dark)
                .onAppear {
                    viewModel.restoreFromStorage()

                    // Show onboarding on first launch
                    if !hasSeenOnboarding {
                        showOnboarding = true
                    }
                }
                .onChange(of: importStatus.isImportComplete) { _, isComplete in
                    if isComplete {
                        // Trigger a refresh to load verses after import completes
                        refreshTrigger = UUID()
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                        .onDisappear {
                            hasSeenOnboarding = true
                        }
                }
                .sheet(item: $noteEditorMode) { mode in
                    switch mode {
                    case .newNote(let verse):
                        NoteEditorView(verse: verse)
                    case .editNote(let note):
                        NoteEditorView(existingNote: note)
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(hapticFeedbackEnabled: $hapticFeedbackEnabled)
                        .presentationDetents([.height(420)])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showBookPicker) {
                    bookPickerSheet()
                }
                .sheet(isPresented: $showChapterPicker) {
                    chapterPickerSheet()
                }
                .navigationDestination(isPresented: $showReadingHistory) {
                    ReadingHistoryView { bookName, chapterNumber, verseNumber in
                        viewModel.suppressChapterReset = true
                        viewModel.selectedBook = bookName
                        viewModel.selectedChapter = chapterNumber
                        scrollToVerse = verseNumber
                    }
                }
                .navigationDestination(isPresented: $showDailyVerse) {
                    DailyVerseView { bookName, chapterNumber, verseNumber in
                        viewModel.suppressChapterReset = true
                        viewModel.selectedBook = bookName
                        viewModel.selectedChapter = chapterNumber
                        scrollToVerse = verseNumber
                    }
                }
            }
        }
    }

    private func versesWithContinuousHighlight(geometry: GeometryProxy) -> some View {
        let groupedVerses = viewModel.groupConsecutiveHighlightedVerses(verses)
        let notedVerses = viewModel.fetchVerseNumbersWithNotes(context: modelContext)

        return VStack(alignment: .leading, spacing: geometry.size.height * 0.02) {
            ForEach(groupedVerses, id: \.id) { group in
                let hasHighlight = group.highlightColor != nil
                VStack(alignment: .leading, spacing: hasHighlight ? 0 : geometry.size.height * 0.02) {
                    ForEach(group.verses) { verse in
                        HStack(alignment: .top, spacing: geometry.size.width * 0.015) {
                            HStack(alignment: .top, spacing: 2) {
                                Text("\(verse.verseNumber)")
                                    .font(.system(size: verseNumberFontSize, weight: .medium, design: .serif))
                                    .foregroundColor(.secondary)

                                if notedVerses.contains(verse.verseNumber) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: verseNumberFontSize * 0.55))
                                        .foregroundColor(.secondary)
                                        .onTapGesture {
                                            HapticManager.shared.impact(style: .light)
                                            openNoteForVerse(verse)
                                        }
                                }
                            }
                            .frame(width: geometry.size.width * 0.08, alignment: .leading)
                            .onLongPressGesture(minimumDuration: 0.3) {
                                viewModel.copyVerseReference(verse)
                            }

                            Text(verse.text)
                                .font(.system(size: verseFontSize, weight: .regular, design: .serif))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)
                        .padding(.vertical, hasHighlight ? 4 : 0)
                        .id(verse.verseNumber)
                        .contextMenu {
                            // Highlight color picker
                            Menu {
                                ForEach(BibleVerse.availableColors, id: \.name) { option in
                                    Button {
                                        viewModel.setHighlightColor(option.name, for: verse, context: modelContext)
                                    } label: {
                                        Label(highlightColorLabel(option.name), systemImage: verse.highlightColor == option.name ? "checkmark.circle.fill" : "circle.fill")
                                    }
                                }

                                if verse.highlightColor != nil {
                                    Divider()
                                    Button(role: .destructive) {
                                        viewModel.removeHighlight(for: verse, context: modelContext)
                                    } label: {
                                        Label("Desmarcar", systemImage: "bookmark.slash")
                                    }
                                }
                            } label: {
                                Label(verse.highlightColor != nil ? "Cor do marcador" : "Marcar", systemImage: "bookmark")
                            }

                            Button {
                                HapticManager.shared.impact(style: .light)
                                noteEditorMode = .newNote(verse)
                            } label: {
                                Label("Adicionar Nota", systemImage: "note.text")
                            }

                            Button {
                                HapticManager.shared.impact(style: .light)
                                viewModel.copyVerseWithText(verse)
                            } label: {
                                Label("Copiar", systemImage: "doc.on.doc")
                            }

                            Button {
                                HapticManager.shared.impact(style: .light)
                                viewModel.shareVerse(verse)
                            } label: {
                                Label("Compartilhar", systemImage: "square.and.arrow.up")
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            // Quick-highlight with yellow on long press
                            if verse.highlightColor != nil {
                                viewModel.removeHighlight(for: verse, context: modelContext)
                            } else {
                                viewModel.setHighlightColor("yellow", for: verse, context: modelContext)
                            }
                        }
                    }
                }
                .background(
                    Rectangle()
                        .fill(group.verses.first?.highlightSwiftUIColor ?? Color.clear)
                        .frame(maxWidth: .infinity)
                )
                .cornerRadius(hasHighlight ? 8 : 0)
            }
        }
    }

    private func highlightColorLabel(_ colorName: String) -> String {
        switch colorName {
        case "yellow": return "Amarelo"
        case "green": return "Verde"
        case "blue": return "Azul"
        case "pink": return "Rosa"
        default: return colorName.capitalized
        }
    }

    private func headerView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: geometry.size.width * 0.02) {
                // Book selector
                Button {
                    showBookPicker = true
                } label: {
                    HStack {
                        Text(viewModel.selectedBook)
                            .font(.system(size: headerFontSize, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: headerFontSize * 0.6))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, geometry.size.width * 0.03)
                    .padding(.vertical, geometry.size.height * 0.01)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }

                // Chapter selector
                Button {
                    showChapterPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Cap. \(viewModel.selectedChapter)")
                            .font(.system(size: headerFontSize, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: headerFontSize * 0.6))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, geometry.size.width * 0.03)
                    .padding(.vertical, geometry.size.height * 0.01)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                .fixedSize()

                // Spacer between selectors and action buttons
                Spacer()

                // Speaker button
                Button {
                    HapticManager.shared.impact(style: .medium)
                    if viewModel.speechSynthesizer.isSpeaking {
                        viewModel.speechSynthesizer.stopSpeaking(at: .immediate)
                    } else {
                        viewModel.readCurrentChapter(verses: verses, rate: Float(speechRate))
                    }
                } label: {
                    Image(systemName: viewModel.speechSynthesizer.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.system(size: headerFontSize * 0.7))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }

                // Search button
                NavigationLink {
                    SearchView { bookName, chapterNumber, verseNumber in
                        viewModel.suppressChapterReset = true
                        viewModel.selectedBook = bookName
                        viewModel.selectedChapter = chapterNumber
                        scrollToVerse = verseNumber
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: headerFontSize * 0.7))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
            }
            .padding(.horizontal, geometry.size.width * 0.04)
            .padding(.top, geometry.size.height * 0.01)
            .padding(.bottom, geometry.size.height * 0.01)
            .background(
                Color.black
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1),
                        alignment: .bottom
                    )
            )
        }
    }

    private func floatingActionButtons() -> some View {
        ZStack {
            if !showFontSizeSlider {
                // Regular buttons
                HStack {
                    // Left side buttons
                    HStack(spacing: 20) {
                        // Settings button
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        // Reading history button
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showReadingHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        // Daily verse button
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showDailyVerse = true
                        } label: {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }

                    Spacer()

                    // Right side buttons
                    HStack(spacing: 20) {
                        // Notes button
                        NavigationLink {
                                NotesView { bookName, chapterNumber, verseNumber in
                                    viewModel.suppressChapterReset = true
                                    viewModel.selectedBook = bookName
                                    viewModel.selectedChapter = chapterNumber
                                    scrollToVerse = verseNumber
                                }
                        } label: {
                            Image(systemName: "note.text")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        // Bookmarks button
                        NavigationLink {
                                HighlightedVersesView { bookName, chapterNumber, verseNumber in
                                    viewModel.suppressChapterReset = true
                                    viewModel.selectedBook = bookName
                                    viewModel.selectedChapter = chapterNumber
                                    scrollToVerse = verseNumber
                                }
                        } label: {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        // Font size button
                        Button {
                            HapticManager.shared.impact(style: .light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showFontSizeSlider = true
                            }
                        } label: {
                            Text("Aa")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            } else {
                // Font size slider
                fontSizeSlider()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func fontSizeSlider() -> some View {
        HStack(spacing: 16) {
            // Close button
            Button {
                HapticManager.shared.impact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showFontSizeSlider = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            // Smaller A
            Text("A")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))

            // Slider
            Slider(
                value: $fontSize,
                in: 15...31,
                step: 2,
                onEditingChanged: { editing in
                    if !editing {
                        HapticManager.shared.impact(style: .light)
                    }
                }
            )
            .accentColor(.white)

            // Larger A
            Text("A")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
    
    private func openNoteForVerse(_ verse: BibleVerse) {
        if let existingNote = viewModel.findNoteForVerse(verse, context: modelContext) {
            noteEditorMode = .editNote(existingNote)
        }
    }

    // MARK: - Book Picker Sheet
    private func bookPickerSheet() -> some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                List {
                    ForEach(BibleData.orderedBookNames, id: \.self) { book in
                        Button {
                            HapticManager.shared.impact(style: .light)
                            viewModel.selectedBook = book
                            showBookPicker = false
                        } label: {
                            HStack {
                                Text(book)
                                    .font(.system(size: 17, weight: book == viewModel.selectedBook ? .bold : .regular, design: .serif))
                                    .foregroundColor(book == viewModel.selectedBook ? .accentColor : .primary)
                                Spacer()
                                if book == viewModel.selectedBook {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .id(book)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(viewModel.selectedBook, anchor: .center)
                        }
                    }
                }
            }
            .navigationTitle("Livro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        showBookPicker = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Chapter Picker Sheet
    private func chapterPickerSheet() -> some View {
        let totalChapters = BibleData.numberOfChapters(forBook: viewModel.selectedBook) ?? 1
        let columns = [GridItem(.adaptive(minimum: 56))]

        return NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(1...totalChapters, id: \.self) { chapter in
                            Button {
                                HapticManager.shared.impact(style: .light)
                                viewModel.selectedChapter = chapter
                                showChapterPicker = false
                            } label: {
                                Text("\(chapter)")
                                    .font(.system(size: 17, weight: chapter == viewModel.selectedChapter ? .bold : .regular, design: .serif))
                                    .foregroundColor(chapter == viewModel.selectedChapter ? .white : .primary)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(chapter == viewModel.selectedChapter ? Color.accentColor : Color(.systemGray5))
                                    )
                            }
                            .id(chapter)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(viewModel.selectedChapter, anchor: .center)
                        }
                    }
                }
            }
            .navigationTitle("Capítulo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        showChapterPicker = false
                    }
                }
            }
        }
        .presentationDetents(totalChapters > 30 ? [.medium, .large] : [.medium])
        .preferredColorScheme(.dark)
    }

    private var currentTransition: AnyTransition {
        switch currentTranslationDirection {
        case .left:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .right:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        case .none:
            return .identity
        }
    }
}
