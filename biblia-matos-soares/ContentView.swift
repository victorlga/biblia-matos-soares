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
    @AppStorage("lastSelectedBook") private var storedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @AppStorage("lastSelectedChapter") private var storedChapter: Int = 1
    @AppStorage("readingHistory") private var readingHistoryData: Data = Data()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("fontSize") private var fontSize: Double = 17.0 // Default system font size
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true // Default ON

    @State private var showOnboarding: Bool = false
    @State private var showFontSizeSlider: Bool = false
    @State private var showSettings: Bool = false
    @State private var showReadingHistory: Bool = false
    @State private var showDailyVerse: Bool = false

    @State private var selectedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @State private var selectedChapter: Int = 1
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentTranslationDirection: HorizontalTransitionDirection = .none
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
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
        do {
            let descriptor = FetchDescriptor<BibleVerse>(
                predicate: #Predicate { verse in
                    verse.bookName == selectedBook && verse.chapterNumber == selectedChapter
                },
                sortBy: [SortDescriptor(\.verseNumber, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
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
                                            if speechSynthesizer.isSpeaking {
                                                speechSynthesizer.stopSpeaking(at: .immediate)
                                            }

                                            if horizontalTranslation > 50 {
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    currentTranslationDirection = .right
                                                    goToPreviousChapter()
                                                }
                                            } else if horizontalTranslation < -50 {
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    currentTranslationDirection = .left
                                                    goToNextChapter()
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
                            .onChange(of: selectedBook) { _, newBook in
                                if speechSynthesizer.isSpeaking {
                                    speechSynthesizer.stopSpeaking(at: .immediate)
                                }
                                withAnimation(.easeOut(duration: 0.3)) {
                                    selectedChapter = 1
                                    let targetVerse = scrollToVerse ?? 1
                                    scrollToVerse = nil
                                    proxy.scrollTo(targetVerse, anchor: .top)
                                    storedBook = newBook
                                    storedChapter = selectedChapter
                                    updateReadingHistory()
                                }
                            }
                            .onChange(of: selectedChapter) { _, newChapter in
                                if speechSynthesizer.isSpeaking {
                                    speechSynthesizer.stopSpeaking(at: .immediate)
                                }
                                withAnimation(.easeOut(duration: 0.3)) {
                                    let targetVerse = scrollToVerse ?? 1
                                    scrollToVerse = nil
                                    proxy.scrollTo(targetVerse, anchor: .top)
                                    storedChapter = newChapter
                                    updateReadingHistory()
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
                    selectedBook = storedBook
                    selectedChapter = storedChapter
                    updateReadingHistory()

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
                        .presentationDetents([.height(260)])
                        .presentationDragIndicator(.visible)
                }
                .navigationDestination(isPresented: $showReadingHistory) {
                    ReadingHistoryView { bookName, chapterNumber, verseNumber in
                        selectedBook = bookName
                        selectedChapter = chapterNumber
                        scrollToVerse = verseNumber
                    }
                }
                .navigationDestination(isPresented: $showDailyVerse) {
                    DailyVerseView { bookName, chapterNumber, verseNumber in
                        selectedBook = bookName
                        selectedChapter = chapterNumber
                        scrollToVerse = verseNumber
                    }
                }
            }
        }
    }

    private var verseNumbersWithNotes: Set<Int> {
        let book = selectedBook
        let chapter = selectedChapter
        do {
            let descriptor = FetchDescriptor<VerseNote>(
                predicate: #Predicate { note in
                    note.bookName == book && note.chapterNumber == chapter
                }
            )
            let notes = try modelContext.fetch(descriptor)
            return Set(notes.map { $0.verseNumber })
        } catch {
            return []
        }
    }

    // Nova função para renderizar versículos com destaque contínuo
    private func versesWithContinuousHighlight(geometry: GeometryProxy) -> some View {
        let groupedVerses = groupConsecutiveHighlightedVerses(verses)
        let notedVerses = verseNumbersWithNotes

        return VStack(alignment: .leading, spacing: geometry.size.height * 0.02) {
            ForEach(groupedVerses, id: \.id) { group in
                VStack(alignment: .leading, spacing: group.isHighlighted ? 0 : geometry.size.height * 0.02) {
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
                                copyVerseReference(verse)
                            }

                            Text(verse.text)
                                .font(.system(size: verseFontSize, weight: .regular, design: .serif))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)
                        .padding(.vertical, group.isHighlighted ? 4 : 0)
                        .id(verse.verseNumber)
                        .contextMenu {
                            Button {
                                toggleHighlight(for: verse)
                            } label: {
                                Label(verse.isHighlighted ? "Desmarcar" : "Marcar", systemImage: verse.isHighlighted ? "bookmark.slash" : "bookmark")
                            }

                            Button {
                                HapticManager.shared.impact(style: .light)
                                noteEditorMode = .newNote(verse)
                            } label: {
                                Label("Adicionar Nota", systemImage: "note.text")
                            }

                            Button {
                                HapticManager.shared.impact(style: .light)
                                copyVerseWithText(verse)
                            } label: {
                                Label("Copiar", systemImage: "doc.on.doc")
                            }

                            Button {
                                HapticManager.shared.impact(style: .light)
                                shareVerse(verse)
                            } label: {
                                Label("Compartilhar", systemImage: "square.and.arrow.up")
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            toggleHighlight(for: verse)
                        }
                    }
                }
                .background(
                    // Fundo que se estende por toda a largura
                    Rectangle()
                        .fill(group.isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
                        .frame(maxWidth: .infinity)
                )
                .cornerRadius(group.isHighlighted ? 8 : 0)
            }
        }
    }

    // Estrutura para agrupar versículos
    private struct VerseGroup {
        let id = UUID()
        let verses: [BibleVerse]
        let isHighlighted: Bool
    }

    // Função para agrupar versículos consecutivos destacados
    private func groupConsecutiveHighlightedVerses(_ verses: [BibleVerse]) -> [VerseGroup] {
        var groups: [VerseGroup] = []
        var currentGroup: [BibleVerse] = []
        var currentHighlightState: Bool = false
        
        for verse in verses {
            if currentGroup.isEmpty {
                // Primeiro versículo
                currentGroup.append(verse)
                currentHighlightState = verse.isHighlighted
            } else if verse.isHighlighted == currentHighlightState {
                // Mesmo estado de destaque, adicionar ao grupo atual
                currentGroup.append(verse)
            } else {
                // Estado de destaque mudou, criar novo grupo
                groups.append(VerseGroup(verses: currentGroup, isHighlighted: currentHighlightState))
                currentGroup = [verse]
                currentHighlightState = verse.isHighlighted
            }
        }
        
        // Adicionar o último grupo
        if !currentGroup.isEmpty {
            groups.append(VerseGroup(verses: currentGroup, isHighlighted: currentHighlightState))
        }
        
        return groups
    }

    private func goToPreviousChapter() {
        let currentBookIndex = BibleData.orderedBookNames.firstIndex(of: selectedBook) ?? 0

        if selectedChapter > 1 {
            selectedChapter -= 1
        } else if currentBookIndex > 0 {
            let previousBookName = BibleData.orderedBookNames[currentBookIndex - 1]
            selectedBook = previousBookName
            selectedChapter = BibleData.numberOfChapters(forBook: previousBookName) ?? 1
        } else {
            selectedBook = BibleData.orderedBookNames.last ?? "Apocalipse"
            selectedChapter = BibleData.numberOfChapters(forBook: selectedBook) ?? 1
        }
    }

    private func goToNextChapter() {
        let currentBookIndex = BibleData.orderedBookNames.firstIndex(of: selectedBook) ?? 0
        let numberOfChaptersInCurrentBook = BibleData.numberOfChapters(forBook: selectedBook) ?? 1

        if selectedChapter < numberOfChaptersInCurrentBook {
            selectedChapter += 1
        } else if currentBookIndex < BibleData.orderedBookNames.count - 1 {
            let nextBookName = BibleData.orderedBookNames[currentBookIndex + 1]
            selectedBook = nextBookName
            selectedChapter = 1
        } else {
            selectedBook = BibleData.orderedBookNames.first ?? "Gênesis"
            selectedChapter = 1
        }
    }

    private func headerView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: geometry.size.width * 0.02) {
                // Book selector
                Menu {
                    ForEach(BibleData.orderedBookNames, id: \.self) { book in
                        Button(book) {
                            selectedBook = book
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedBook)
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
                Menu {
                    ForEach(1..<(BibleData.numberOfChapters(forBook: selectedBook) ?? 1) + 1, id: \.self) { chapter in
                        Button("Capítulo \(chapter)") {
                            selectedChapter = chapter
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Cap. \(selectedChapter)")
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
                    if speechSynthesizer.isSpeaking {
                        speechSynthesizer.stopSpeaking(at: .immediate)
                    } else {
                        readCurrentChapter()
                    }
                } label: {
                    Image(systemName: speechSynthesizer.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
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
                        selectedBook = bookName
                        selectedChapter = chapterNumber
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
                                    selectedBook = bookName
                                    selectedChapter = chapterNumber
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
                                    selectedBook = bookName
                                    selectedChapter = chapterNumber
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
    
    private func readCurrentChapter() {
        let fullChapterText = verses.map { $0.text }.joined(separator: " ")
        let utterance = AVSpeechUtterance(string: fullChapterText)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        speechSynthesizer.speak(utterance)
    }
    
    private func openNoteForVerse(_ verse: BibleVerse) {
        let book = verse.bookName
        let chapter = verse.chapterNumber
        let verseNum = verse.verseNumber
        do {
            let descriptor = FetchDescriptor<VerseNote>(
                predicate: #Predicate { note in
                    note.bookName == book && note.chapterNumber == chapter && note.verseNumber == verseNum
                }
            )
            if let existingNote = try modelContext.fetch(descriptor).first {
                noteEditorMode = .editNote(existingNote)
            }
        } catch {
            print("Erro ao buscar nota: \(error.localizedDescription)")
        }
    }

    private func toggleHighlight(for verse: BibleVerse) {
        verse.isHighlighted.toggle()
        HapticManager.shared.impact(style: .medium)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save highlight change: \(error.localizedDescription)")
        }
    }
    
    private func copyVerseReference(_ verse: BibleVerse) {
        let reference = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber)"
        UIPasteboard.general.string = reference
        HapticManager.shared.notification(type: .success)
    }

    private func copyVerseWithText(_ verse: BibleVerse) {
        let fullText = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber) - \(verse.text)"
        UIPasteboard.general.string = fullText
        HapticManager.shared.notification(type: .success)
    }
    
    private func shareVerse(_ verse: BibleVerse) {
        let shareText = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber) - \(verse.text)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func updateReadingHistory() {
        let historyItem = "\(selectedBook)|\(selectedChapter)"
        var history: [String] = []
        
        if let decoded = try? JSONDecoder().decode([String].self, from: readingHistoryData) {
            history = decoded
        }
        
        // Remove if already exists
        history.removeAll { $0 == historyItem }
        // Add to front
        history.insert(historyItem, at: 0)
        // Keep only last 10
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            readingHistoryData = encoded
        }
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
