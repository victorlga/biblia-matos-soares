import SwiftUI
import SwiftData

// Estrutura auxiliar para agrupar versículos por capítulo
struct GroupedChapter: Identifiable {
    let id = UUID()
    let bookName: String
    let chapterNumber: Int
    let verses: [BibleVerse]
}

struct HighlightedVersesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var highlightedVerses: [BibleVerse]

    @State private var selectedColorFilter: String? = nil
    
    // Callback para navegar para um versículo específico no ContentView
    var onNavigateToVerse: ((String, Int, Int) -> Void)?

    init(onNavigateToVerse: ((String, Int, Int) -> Void)? = nil) {
        self.onNavigateToVerse = onNavigateToVerse
        _highlightedVerses = Query(
            filter: #Predicate<BibleVerse> { verse in
                verse.highlightColor != nil
            },
            sort: [
                SortDescriptor(\.bookName, comparator: .localizedStandard),
                SortDescriptor(\.chapterNumber, order: .forward),
                SortDescriptor(\.verseNumber, order: .forward)
            ]
        )
    }

    // Filtra e ordena os versículos destacados
    private var sortedHighlightedVerses: [BibleVerse] {
        let filtered: [BibleVerse]
        if let colorFilter = selectedColorFilter {
            filtered = highlightedVerses.filter { $0.highlightColor == colorFilter }
        } else {
            filtered = Array(highlightedVerses)
        }

        return filtered.sorted { v1, v2 in
            let order1 = BibleData.bookOrderMap[v1.bookName] ?? 999
            let order2 = BibleData.bookOrderMap[v2.bookName] ?? 999

            if order1 != order2 {
                return order1 < order2
            } else if v1.chapterNumber != v2.chapterNumber {
                return v1.chapterNumber < v2.chapterNumber
            } else {
                return v1.verseNumber < v2.verseNumber
            }
        }
    }

    // Agrupa versículos destacados por livro e capítulo
    private var groupedHighlightedVerses: [GroupedChapter] {
        var groups: [GroupedChapter] = []
        var currentBook: String?
        var currentChapter: Int?
        var verses: [BibleVerse] = []

        for verse in sortedHighlightedVerses {
            if verse.bookName != currentBook || verse.chapterNumber != currentChapter {
                if let book = currentBook, let chapter = currentChapter, !verses.isEmpty {
                    groups.append(GroupedChapter(bookName: book, chapterNumber: chapter, verses: verses))
                }
                currentBook = verse.bookName
                currentChapter = verse.chapterNumber
                verses = [verse]
            } else {
                verses.append(verse)
            }
        }

        if let book = currentBook, let chapter = currentChapter, !verses.isEmpty {
            groups.append(GroupedChapter(bookName: book, chapterNumber: chapter, verses: verses))
        }

        return groups
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Barra superior personalizada
                HStack {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Text("Voltar")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
                .background(
                    Color.black
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1),
                            alignment: .bottom
                        )
                )

                // Color filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "All" filter
                        Button {
                            HapticManager.shared.impact(style: .light)
                            selectedColorFilter = nil
                        } label: {
                            Text("Todos")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedColorFilter == nil ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedColorFilter == nil ? Color.white : Color.gray.opacity(0.3))
                                .cornerRadius(16)
                        }

                        ForEach(BibleVerse.availableColors, id: \.name) { option in
                            Button {
                                HapticManager.shared.impact(style: .light)
                                selectedColorFilter = option.name
                            } label: {
                                Circle()
                                    .fill(option.color.opacity(0.6))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(selectedColorFilter == option.name ? Color.white : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                if sortedHighlightedVerses.isEmpty {
                    Spacer()
                    Text(selectedColorFilter != nil
                         ? "Nenhum versículo marcado com esta cor."
                         : "Nenhum versículo marcado. Toque e segure um versículo para marcá-lo.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedHighlightedVerses) { group in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Header do capítulo
                                    HStack {
                                        Text("\(group.bookName), Cap. \(group.chapterNumber)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                    
                                    // Versículos do capítulo
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(group.verses) { verse in
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text("\(verse.verseNumber). \(verse.text)")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(verse.highlightSwiftUIColor ?? Color.yellow.opacity(0.3))
                                                    .cornerRadius(8)
                                                    .contextMenu {
                                                        Button {
                                                            HapticManager.shared.impact(style: .light)
                                                            openVerse(verse)
                                                        } label: {
                                                            Label("Abrir", systemImage: "book.closed")
                                                        }

                                                        Button(role: .destructive) {
                                                            HapticManager.shared.impact(style: .medium)
                                                            removeHighlight(for: verse)
                                                        } label: {
                                                            Label("Desmarcar", systemImage: "bookmark.slash")
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }

    // Função para abrir um versículo no ContentView
    private func openVerse(_ verse: BibleVerse) {
        onNavigateToVerse?(verse.bookName, verse.chapterNumber, verse.verseNumber)
        dismiss()
    }

    // Remove o destaque do versículo
    private func removeHighlight(for verse: BibleVerse) {
        verse.highlightColor = nil
        verse.isHighlighted = false
        do {
            try modelContext.save()
        } catch {
            print("Failed to save highlight change: \(error.localizedDescription)")
        }
    }
}
