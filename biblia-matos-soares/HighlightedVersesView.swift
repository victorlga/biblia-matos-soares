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

    init() {
        _highlightedVerses = Query(
            filter: #Predicate<BibleVerse> { verse in
                verse.isHighlighted == true
            },
            sort: [
                SortDescriptor(\.bookName, comparator: .localizedStandard),
                SortDescriptor(\.chapterNumber, order: .forward),
                SortDescriptor(\.verseNumber, order: .forward)
            ]
        )
    }

    // Ordena os versículos destacados com base na ordem da Bíblia
    private var sortedHighlightedVerses: [BibleVerse] {
        highlightedVerses.sorted { v1, v2 in
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

                if sortedHighlightedVerses.isEmpty {
                    Spacer()
                    Text("Nenhum versículo destacado ainda.")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(groupedHighlightedVerses) { group in
                            Section {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(group.verses) { verse in
                                        Text("\(verse.verseNumber). \(verse.text)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .onLongPressGesture(minimumDuration: 0.5) {
                                                toggleHighlight(for: verse)
                                            }
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.yellow.opacity(0.3))
                                .cornerRadius(10)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            } header: {
                                ZStack(alignment: .leading) {
                                    Color.black
                                    Text("\(group.bookName), Cap. \(group.chapterNumber)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.top, 12)
                                        .padding(.bottom, 8)
                                        .padding(.leading, 16)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }

    // Alterna o destaque do versículo e salva
    private func toggleHighlight(for verse: BibleVerse) {
        verse.isHighlighted.toggle()
        do {
            try modelContext.save()
            print("Highlight toggled for verse \(verse.verseNumber) in \(verse.bookName) \(verse.chapterNumber)")
        } catch {
            print("Failed to save highlight change: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HighlightedVersesView()
        .modelContainer(for: BibleVerse.self, inMemory: true)
}
