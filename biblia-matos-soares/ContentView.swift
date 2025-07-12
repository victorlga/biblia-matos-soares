import SwiftUI
import SwiftData

struct ContentView: View {
    // Persist last selected book and chapter
    @AppStorage("lastSelectedBook") private var storedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @AppStorage("lastSelectedChapter") private var storedChapter: Int = 1

    @State private var selectedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @State private var selectedChapter: Int = 1
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Dynamic font scaling based on device
    private var verseFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 24 // Smaller screens (e.g., iPhone)
        case .regular: return 34 // Larger screens (e.g., iPad)
        default: return 24
        }
    }

    private var verseNumberFontSize: CGFloat {
        verseFontSize // Scale verse number relative to verse text
    }

    private var headerFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 20
        case .regular: return 28
        default: return 20
        }
    }

    // Dynamic query for verses
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
            print("Error fetching verses: \(error)")
            return []
        }
    }

    var body: some View {
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
                                    Text("Carregando versículos ou nenhum versículo encontrado para \(selectedBook) \(selectedChapter).\nVerifique se os dados da Bíblia foram importados.")
                                        .font(.system(size: headerFontSize, weight: .regular, design: .serif))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(geometry.size.width * 0.05)
                                } else {
                                    ForEach(verses) { verse in
                                        HStack(alignment: .top, spacing: geometry.size.width * 0.015) {
                                            Text("\(verse.verseNumber)")
                                                .font(.system(size: verseNumberFontSize, weight: .medium, design: .serif))
                                                .foregroundColor(.secondary)
                                                .frame(width: geometry.size.width * 0.08, alignment: .leading)

                                            Text(verse.text)
                                                .font(.system(size: verseFontSize, weight: .regular, design: .serif))
                                                .foregroundColor(.primary)
                                                .lineSpacing(4)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(.horizontal, geometry.size.width * 0.05)
                                        .id(verse.verseNumber)
                                    }
                                }

                                Color.clear
                                    .frame(height: geometry.size.height * 0.1)
                            }
                            .padding(.top, geometry.size.height * 0.02)
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
                                        if horizontalTranslation > 50 {
                                            goToPreviousChapter()
                                        } else if horizontalTranslation < -50 {
                                            goToNextChapter()
                                        }
                                    }
                                    isDragging = false
                                    dragOffset = .zero
                                }
                        )
                        .onChange(of: selectedBook) { _, newBook in
                            selectedChapter = 1
                            proxy.scrollTo(1, anchor: .top)
                            storedBook = newBook
                            storedChapter = selectedChapter
                        }
                        .onChange(of: selectedChapter) { _, newChapter in
                            proxy.scrollTo(1, anchor: .top)
                            storedChapter = newChapter
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                selectedBook = storedBook
                selectedChapter = storedChapter
            }
        }
    }

    // MARK: - Navigation Logic

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

    // MARK: - Header View

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
                        Text("Cap. \(selectedChapter)")
                            .font(.system(size: headerFontSize, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
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
}

#Preview {
    ContentView()
        .modelContainer(for: BibleVerse.self, inMemory: true)
}
