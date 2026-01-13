import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct ContentView: View {
    @AppStorage("lastSelectedBook") private var storedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @AppStorage("lastSelectedChapter") private var storedChapter: Int = 1
    @AppStorage("readingHistory") private var readingHistoryData: Data = Data()

    @State private var selectedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @State private var selectedChapter: Int = 1
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentTranslationDirection: HorizontalTransitionDirection = .none
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var showingNoteEditor = false
    @State private var verseForNote: BibleVerse?
    @State private var noteToEdit: VerseNote?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var verseFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 24
        case .regular: return 34
        default: return 24
        }
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
                                    if verses.isEmpty {
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
                                        .frame(height: geometry.size.height * 0.1)
                                }
                                .padding(.top, geometry.size.height * 0.02)
                                .transition(currentTransition)
                            }
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
                                    proxy.scrollTo(1, anchor: .top)
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
                                    proxy.scrollTo(1, anchor: .top)
                                    storedChapter = newChapter
                                    updateReadingHistory()
                                }
                            }
                        }
                    }
                }
                .preferredColorScheme(.dark)
                .onAppear {
                    selectedBook = storedBook
                    selectedChapter = storedChapter
                    updateReadingHistory()
                }
                .sheet(isPresented: $showingNoteEditor) {
                    if let note = noteToEdit {
                        NoteEditorView(existingNote: note)
                    } else if let verse = verseForNote {
                        NoteEditorView(verse: verse)
                    }
                }
            }
        }
    }

    // Nova função para renderizar versículos com destaque contínuo
    private func versesWithContinuousHighlight(geometry: GeometryProxy) -> some View {
        let groupedVerses = groupConsecutiveHighlightedVerses(verses)
        
        return VStack(alignment: .leading, spacing: geometry.size.height * 0.02) {
            ForEach(groupedVerses, id: \.id) { group in
                VStack(alignment: .leading, spacing: group.isHighlighted ? 0 : geometry.size.height * 0.02) {
                    ForEach(group.verses) { verse in
                        HStack(alignment: .top, spacing: geometry.size.width * 0.015) {
                            Text("\(verse.verseNumber)")
                                .font(.system(size: verseNumberFontSize, weight: .medium, design: .serif))
                                .foregroundColor(.secondary)
                                .frame(width: geometry.size.width * 0.08, alignment: .leading)
                                .onLongPressGesture(minimumDuration: 0.3) {
                                    let reference = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber)"
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
                                verseForNote = verse
                                noteToEdit = nil
                                showingNoteEditor = true
                            } label: {
                                Label("Adicionar Nota", systemImage: "note.text")
                            }
                            
                            Button {
                                copyVerseReference(verse)
                            } label: {
                                Label("Copiar Referência", systemImage: "doc.on.doc")
                            }
                            
                            Button {
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
            HStack {
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
                            .lineLimit(1) // Ensures the book name is on a single line
                            .truncationMode(.tail) // Truncates if needed
                        Image(systemName: "chevron.down")
                            .font(.system(size: headerFontSize * 0.7))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, geometry.size.width * 0.04)
                    .padding(.vertical, geometry.size.height * 0.01)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }

                Menu {
                    ForEach(1..<(BibleData.numberOfChapters(forBook: selectedBook) ?? 1) + 1, id: \.self) { chapter in
                        Button("Capítulo \(chapter)") {
                            selectedChapter = chapter
                        }
                    }
                } label: {
                    HStack {
                        Text("\(selectedChapter)")
                            .font(.system(size: headerFontSize, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Image(systemName: "chevron.down")
                            .font(.system(size: headerFontSize * 0.7))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, geometry.size.width * 0.04)
                    .padding(.vertical, geometry.size.height * 0.01)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Spacer()
                
                Button {
                    if speechSynthesizer.isSpeaking {
                        speechSynthesizer.stopSpeaking(at: .immediate)
                    } else {
                        readCurrentChapter()
                    }
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: headerFontSize * 0.8))
                        .foregroundColor(.white)
                        .frame(height: geometry.size.height * 0.045)
                        .padding(.horizontal, geometry.size.width * 0.04)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }

                NavigationLink {
                    SearchView { bookName, chapterNumber in
                        // Callback para navegar para o versículo específico
                        selectedBook = bookName
                        selectedChapter = chapterNumber
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: headerFontSize * 0.8))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
                
                NavigationLink {
                    NotesView { bookName, chapterNumber in
                        // Callback para navegar para o versículo específico
                        selectedBook = bookName
                        selectedChapter = chapterNumber
                    }
                } label: {
                    Image(systemName: "note.text")
                        .font(.system(size: headerFontSize * 0.8))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
                
                NavigationLink {
                    HighlightedVersesView { bookName, chapterNumber in
                        // Callback para navegar para o versículo específico
                        selectedBook = bookName
                        selectedChapter = chapterNumber
                    }
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: headerFontSize * 0.8))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
            }
            .padding(.horizontal, geometry.size.width * 0.05)
            .padding(.top, geometry.size.height * 0.01)
            .padding(.bottom, geometry.size.height * 0.015)
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
    
    private func readCurrentChapter() {
        let fullChapterText = verses.map { $0.text }.joined(separator: " ")
        let utterance = AVSpeechUtterance(string: fullChapterText)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        speechSynthesizer.speak(utterance)
    }
    
    private func toggleHighlight(for verse: BibleVerse) {
        verse.isHighlighted.toggle()
        do {
            try modelContext.save()
        } catch {
            print("Failed to save highlight change: \(error.localizedDescription)")
        }
    }
    
    private func copyVerseReference(_ verse: BibleVerse) {
        let reference = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber)"
        UIPasteboard.general.string = reference
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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

