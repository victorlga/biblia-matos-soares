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
    
    // Você pode manter este mapa, mas ele não é estritamente necessário para a importação
    // apenas se você precisar da ORDEM dos livros durante a importação para algo específico,
    // ou para a lógica de navegação do app.
    let bookOrderMap: [String: Int] = [
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

    func importBible() async {
        guard let url = Bundle.main.url(forResource: "biblia_matos_soares_1956", withExtension: "json") else {
            print("❌ JSON não encontrado.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            
            // Usando Codable para decodificar o JSON de forma mais segura e limpa
            let bibleBooksData = try JSONDecoder().decode([BibleBookImportData].self, from: data)

            for bookData in bibleBooksData {
                let bookName = bookData.name
                
                for (chapterIndex, versesArray) in bookData.chapters.enumerated() {
                    let chapterNumber = chapterIndex + 1 // Capítulos são baseados em 1

                    for verseData in versesArray {
                        let verseNumber = verseData.verse
                        let verseText = verseData.text

                        let newVerse = BibleVerse(bookName: bookName,
                                                  chapterNumber: chapterNumber,
                                                  verseNumber: verseNumber,
                                                  text: verseText)
                        context.insert(newVerse)
                    }
                }
            }

            // O SwiftData normalmente salva automaticamente.
            // Chamar save() explicitamente aqui garante que todos os inserts sejam persistidos de uma vez.
            try context.save()
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
