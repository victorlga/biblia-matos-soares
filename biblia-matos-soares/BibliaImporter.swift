//
//  BibliaImporter.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 12/06/25.
//
import Foundation
import SwiftData

@MainActor
class BibleImporter {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func importBible() async {
        guard let url = Bundle.main.url(forResource: "biblia_matos_soares_1956", withExtension: "json") else {
            print("❌ JSON não encontrado.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let bibleBooksData = try JSONDecoder().decode([BibleBookImportData].self, from: data)
            let totalBooks = bibleBooksData.count

            for (bookIndex, bookData) in bibleBooksData.enumerated() {
                autoreleasepool {
                    let bookName = bookData.name

                    for (chapterIndex, versesArray) in bookData.chapters.enumerated() {
                        let chapterNumber = chapterIndex + 1

                        for verseData in versesArray {
                            let newVerse = BibleVerse(bookName: bookName,
                                                      chapterNumber: chapterNumber,
                                                      verseNumber: verseData.verse,
                                                      text: verseData.text)
                            context.insert(newVerse)
                        }
                    }

                    do {
                        try context.save()
                        print("📖 Importado \(bookName) (\(bookIndex + 1)/\(totalBooks))")
                    } catch {
                        print("❌ Erro ao salvar \(bookName): \(error)")
                    }
                }
            }

            print("✅ Bíblia importada com sucesso: \(await countVerses()) versículos.")

        } catch {
            print("❌ Erro ao importar JSON: \(error)")
        }
    }
    
    // Função auxiliar para verificar se já existem versículos, evitando importação duplicada
    func hasImportedData() async -> Bool {
        do {
            let descriptor = FetchDescriptor<BibleVerse>()
            let count = try context.fetch(descriptor).count
            return count > 0
        } catch {
            print("Erro ao verificar dados importados: \(error)")
            return false
        }
    }
    
    // Função auxiliar para contar os versículos (útil para depuração)
    func countVerses() async -> Int {
        do {
            let descriptor = FetchDescriptor<BibleVerse>()
            return try context.fetch(descriptor).count
        } catch {
            print("Erro ao contar versículos: \(error)")
            return 0
        }
    }
}


// MARK: - Modelos Auxiliares para Decodificação JSON

// Representa a estrutura de um Livro no JSON
struct BibleBookImportData: Decodable {
    let name: String
    let num_chapters: Int // Embora não seja usado para criar objetos, é parte do JSON
    let chapters: [[VerseImportData]] // Array de capítulos, onde cada capítulo é um array de versículos
}

// Representa a estrutura de um Versículo dentro de um Capítulo no JSON
struct VerseImportData: Decodable {
    let verse: Int
    let text: String
}
