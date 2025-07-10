import SwiftUI
import SwiftData

// MARK: - BibleData
// Esta struct contém os dados estáticos sobre os livros e capítulos da Bíblia.
// Idealmente, deve estar em seu próprio arquivo (e.g., BibleData.swift).
struct BibleData {
    static let bookOrderMap: [String: Int] = [
        "Gênesis": 1, "Êxodo": 2, "Levítico": 3, "Números": 4, "Deuteronômio": 5,
        "Josué": 6, "Juízes": 7, "Rute": 8, "I Samuel": 9, "II Samuel": 10,
        "I Reis": 11, "II Reis": 12, "I Crônicas": 13, "II Crônicas": 14,
        "Esdras": 15, "Neemias": 16, "Tobias": 17, "Judite": 18, "Ester": 19,
        "Jó": 20, "Salmos": 21, "I Macabeus": 22, "II Macabeus": 23,
        "Provérbios": 24, "Eclesiastes": 25, "Cântico dos Cânticos": 26,
        "Sabedoria": 27, "Eclesiástico": 28, "Isaías": 29, "Jeremias": 30,
        "Lamentações": 31, "Baruc": 32, "Ezequiel": 33, "Daniel": 34,
        "Oséias": 35, "Joel": 36, "Amós": 37, "Abdias": 38, "Jonas": 39,
        "Miquéias": 40, "Naum": 41, "Habacuc": 42, "Sofonias": 43,
        "Ageu": 44, "Zacarias": 45, "Malaquias": 46, "São Mateus": 47,
        "São Marcos": 48, "São Lucas": 49, "São João": 50,
        "Atos dos Apóstolos": 51, "Romanos": 52, "I Coríntios": 53,
        "II Coríntios": 54, "Gálatas": 55, "Efésios": 56, "Filipenses": 57,
        "Colossenses": 58, "I Tessalonicenses": 59, "II Tessalonicenses": 60,
        "I Timóteo": 61, "II Timóteo": 62, "Tito": 63, "Filêmon": 64,
        "Hebreus": 65, "São Tiago": 66, "I São Pedro": 67, "II São Pedro": 68,
        "I São João": 69, "II São João": 70, "III São João": 71,
        "São Judas": 72, "Apocalipse": 73
    ]

    static let bookChapterCounts: [String: Int] = [
        "Gênesis": 50, "Êxodo": 40, "Levítico": 27, "Números": 36, "Deuteronômio": 34,
        "Josué": 24, "Juízes": 21, "Rute": 4, "I Samuel": 31, "II Samuel": 24,
        "I Reis": 22, "II Reis": 25, "I Crônicas": 29, "II Crônicas": 36,
        "Esdras": 10, "Neemias": 13, "Tobias": 14, "Judite": 16, "Ester": 10,
        "Jó": 42, "Salmos": 150, "I Macabeus": 16, "II Macabeus": 15,
        "Provérbios": 31, "Eclesiastes": 12, "Cântico dos Cânticos": 8,
        "Sabedoria": 19, "Eclesiástico": 51, "Isaías": 66, "Jeremias": 52,
        "Lamentações": 5, "Baruc": 6, "Ezequiel": 48, "Daniel": 14,
        "Oséias": 14, "Joel": 4, "Amós": 9, "Abdias": 1, "Jonas": 4,
        "Miquéias": 7, "Naum": 3, "Habacuc": 3, "Sofonias": 3,
        "Ageu": 2, "Zacarias": 14, "Malaquias": 3,
        "São Mateus": 28, "São Marcos": 16, "São Lucas": 24, "São João": 21,
        "Atos dos Apóstolos": 28, "Romanos": 16, "I Coríntios": 16,
        "II Coríntios": 13, "Gálatas": 6, "Efésios": 6, "Filipenses": 4,
        "Colossenses": 4, "I Tessalonicenses": 5, "II Tessalonicenses": 3,
        "I Timóteo": 6, "II Timóteo": 4, "Tito": 3, "Filêmon": 1,
        "Hebreus": 13, "São Tiago": 5, "I São Pedro": 5, "II São Pedro": 3,
        "I São João": 5, "II São João": 1, "III São João": 1,
        "São Judas": 1, "Apocalipse": 22
    ]

    static let orderedBookNames: [String] = {
        bookOrderMap.sorted { $0.value < $1.value }.map { $0.key }
    }()

    static func numberOfChapters(forBook bookName: String) -> Int? {
        return bookChapterCounts[bookName]
    }
}

// MARK: - ContentView
struct ContentView: View {
    // @AppStorage para persistir o último livro e capítulo lidos entre as sessões do app.
    @AppStorage("lastSelectedBook") private var storedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @AppStorage("lastSelectedChapter") private var storedChapter: Int = 1

    @State private var selectedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @State private var selectedChapter: Int = 1

    @Query private var verses: [BibleVerse]

    @Environment(\.modelContext) private var modelContext

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
                        LazyVStack(alignment: .leading, spacing: 20) {
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
                        // Valida se o capítulo atual é válido para o novo livro.
                        let maxChapters = BibleData.numberOfChapters(forBook: newBook) ?? 1
                        if selectedChapter > maxChapters {
                            selectedChapter = 1 // Volta para o capítulo 1 se for inválido.
                        }
                        // Rola para o topo do novo capítulo/livro e persiste a seleção.
                        proxy.scrollTo(1, anchor: .top)
                        storedBook = newBook
                        storedChapter = selectedChapter // Persiste o capítulo, caso tenha sido resetado.
                    }
                    // Reage a mudanças no capítulo selecionado.
                    .onChange(of: selectedChapter) { _, newChapter in
                        proxy.scrollTo(1, anchor: .top) // Rola para o topo do novo capítulo.
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
