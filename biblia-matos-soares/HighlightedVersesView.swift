import SwiftUI
import SwiftData

// Estrutura auxiliar para agrupar versículos por capítulo
struct GroupedChapter: Identifiable {
    let id = UUID() // Usado para identificar cada grupo em ForEach
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
    
    // Função de ordenação personalizada para usar BibleData.bookOrderMap
    private var sortedHighlightedVerses: [BibleVerse] {
        highlightedVerses.sorted { (verse1, verse2) in
            let book1Order = BibleData.bookOrderMap[verse1.bookName] ?? 999
            let book2Order = BibleData.bookOrderMap[verse2.bookName] ?? 999
            
            if book1Order != book2Order {
                return book1Order < book2Order
            } else if verse1.chapterNumber != verse2.chapterNumber {
                return verse1.chapterNumber < verse2.chapterNumber
            } else {
                return verse1.verseNumber < verse2.verseNumber
            }
        }
    }

    // Nova propriedade computada para agrupar os versículos destacados
    private var groupedHighlightedVerses: [GroupedChapter] {
        var currentGroups: [GroupedChapter] = []
        var currentBook: String?
        var currentChapter: Int?
        var versesForCurrentChapter: [BibleVerse] = []

        for verse in sortedHighlightedVerses {
            // Verifica se estamos começando um novo livro ou um novo capítulo
            if verse.bookName != currentBook || verse.chapterNumber != currentChapter {
                // Se havia versículos acumulados para o capítulo anterior, adicione-os aos grupos
                if !versesForCurrentChapter.isEmpty {
                    if let book = currentBook, let chapter = currentChapter {
                        currentGroups.append(GroupedChapter(bookName: book, chapterNumber: chapter, verses: versesForCurrentChapter))
                    }
                }
                // Reinicia para o novo livro/capítulo
                currentBook = verse.bookName
                currentChapter = verse.chapterNumber
                versesForCurrentChapter = [verse]
            } else {
                // Continua acumulando versículos para o capítulo atual
                versesForCurrentChapter.append(verse)
            }
        }

        // Adiciona quaisquer versículos restantes após o término do loop
        if !versesForCurrentChapter.isEmpty {
            if let book = currentBook, let chapter = currentChapter {
                currentGroups.append(GroupedChapter(bookName: book, chapterNumber: chapter, verses: versesForCurrentChapter))
            }
        }
        return currentGroups
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Custom Navigation Bar for Highlighted Verses
                HStack {
                    Button {
                        dismiss() // Go back to ContentView
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

                if sortedHighlightedVerses.isEmpty { // Usamos sortedHighlightedVerses para verificar se há algum versículo
                    Spacer()
                    Text("Nenhum versículo destacado ainda.")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(groupedHighlightedVerses) { group in
                            Section {
                                ForEach(group.verses) { verse in
                                    VStack(alignment: .leading) {
                                        Text("\(verse.verseNumber) \(verse.text)") // Formato: Versículo Texto
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                    }
                                    .padding(.vertical, 2) // Espaçamento vertical diminuído
                                    .listRowBackground(verse.isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
                                    .listRowSeparator(.hidden)
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        toggleHighlight(for: verse)
                                    }
                                }
                            } header: {
                                // Formato: ### Livro Capítulo
                                Text("\(group.bookName), Capítulo \(group.chapterNumber)")
                                    .font(.title3) // Ajuste o tamanho da fonte conforme necessário
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.black)
                                    .listRowInsets(EdgeInsets()) // Remove insets padrão para o cabeçalho da seção
                            }
                        }
                        // O listRowInsets para a List pode ser ajustado ou removido se necessário
                        // .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }
    
    private func toggleHighlight(for verse: BibleVerse) {
        verse.isHighlighted.toggle()
        do {
            try modelContext.save()
            print("Verse \(verse.verseNumber) of \(verse.bookName) \(verse.chapterNumber) highlight toggled to \(verse.isHighlighted) from HighlightedVersesView")
        } catch {
            print("Failed to save highlight change from HighlightedVersesView: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HighlightedVersesView()
        .modelContainer(for: BibleVerse.self, inMemory: true)
}
