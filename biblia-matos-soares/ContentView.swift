import SwiftUI
import SwiftData

struct ContentView: View {
    // @AppStorage para persistir o último livro e capítulo lidos entre as sessões do app.
    @AppStorage("lastSelectedBook") private var storedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @AppStorage("lastSelectedChapter") private var storedChapter: Int = 1

    @State private var selectedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @State private var selectedChapter: Int = 1

    @Environment(\.modelContext) private var modelContext

    // Query dinâmica que filtra os versículos baseado no livro e capítulo selecionados
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
            print("Erro ao buscar versículos: \(error)")
            return []
        }
    }

    var body: some View {
        ZStack {
            // Fundo escuro para a interface.
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Cabeçalho da aplicação com os seletores de livro e capítulo.
                headerView
                
                // Área de exibição do texto da Bíblia.
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if verses.isEmpty {
                                Text("Carregando versículos ou nenhum versículo encontrado para \(selectedBook) \(selectedChapter).\nVerifique se os dados da Bíblia foram importados.")
                                    .foregroundColor(.gray)
                                    .padding()
                                    .multilineTextAlignment(.center)
                            } else {
                                ForEach(verses) { verse in
                                    HStack(alignment: .top, spacing: 12) {
                                        // Número do versículo
                                        Text("\(verse.verseNumber)")
                                            .font(.system(size: 20, weight: .medium, design: .serif))
                                            .foregroundColor(.secondary)
                                            .frame(width: 25, alignment: .leading)
                                        
                                        // Texto do versículo
                                        Text(verse.text)
                                            .font(.system(size: 26, weight: .regular, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineSpacing(4)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(.horizontal, 20)
                                    // Usa o número do versículo como ID para rolagem eficiente.
                                    .id(verse.verseNumber)
                                }
                            }
                            
                            // Espaço extra na parte inferior para facilitar a leitura.
                            Color.clear
                                .frame(height: 100)
                        }
                        .padding(.top, 20)
                    }
                    // Reage a mudanças no livro selecionado.
                    .onChange(of: selectedBook) { _, newBook in
                        selectedChapter = 1
                        
                        // Rola para o topo imediatamente
                        proxy.scrollTo("top", anchor: .top)
                        storedBook = newBook
                        storedChapter = selectedChapter // Persiste o capítulo, caso tenha sido resetado.
                    }
                    // Reage a mudanças no capítulo selecionado.
                    .onChange(of: selectedChapter) { _, newChapter in
                        proxy.scrollTo("top", anchor: .top)
                        storedChapter = newChapter // Persiste a seleção.
                    }
                }
            }
        }
        .preferredColorScheme(.dark) // Define o esquema de cores preferencial.
        .onAppear {
            // No `onAppear`, inicializa `selectedBook` e `selectedChapter` a partir de `storedBook` e `storedChapter`.
            // Isso garante que a UI reflita o estado persistido na inicialização do app.
            selectedBook = storedBook
            selectedChapter = storedChapter

            // Garante que o capítulo selecionado seja válido na primeira aparição da View,
            // caso o valor do AppStorage seja inválido para o livro inicial.
            let maxChapters = BibleData.numberOfChapters(forBook: selectedBook) ?? 1
            if selectedChapter > maxChapters {
                selectedChapter = 1
                storedChapter = 1 // Atualiza o AppStorage também.
            }
        }
    }
    
    // MARK: - headerView
    // Sub-view para o cabeçalho com os seletores de livro e capítulo.
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Seletor de Livros (Menu para escolher o livro).
                Menu {
                    ForEach(BibleData.orderedBookNames, id: \.self) { book in
                        Button(book) {
                            selectedBook = book // Isso aciona o .onChange(of: selectedBook) no ScrollViewReader.
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedBook)
                            .font(.system(size: 17, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Seletor de Capítulos (Menu para escolher o capítulo).
                Menu {
                    // O número de capítulos é dinâmico, baseado no livro selecionado.
                    ForEach(1..<(BibleData.numberOfChapters(forBook: selectedBook) ?? 1) + 1, id: \.self) { chapter in
                        Button("Capítulo \(chapter)") {
                            selectedChapter = chapter // Isso aciona o .onChange(of: selectedChapter) no ScrollViewReader.
                        }
                    }
                } label: {
                    HStack {
                        Text("Cap. \(selectedChapter)")
                            .font(.system(size: 17, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Spacer() // Empurra os seletores para a esquerda.
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 15)
            .background(
                Color.black
                    .overlay( // Adiciona uma linha divisória na parte inferior do cabeçalho.
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1),
                        alignment: .bottom
                    )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        // Para o Preview funcionar, é necessário fornecer um ModelContainer.
        // `inMemory: true` cria um banco de dados temporário que não persiste.
        .modelContainer(for: BibleVerse.self, inMemory: true)
}
