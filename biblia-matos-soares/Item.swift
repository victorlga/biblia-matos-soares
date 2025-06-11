//
//  Item.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 10/06/25.
//

import Foundation
import SwiftData

@Model
final class BibleBook {
    var name: String
    var testament: Testament
    var chapters: [BibleChapter]
    
    init(name: String, testament: Testament, chapters: [BibleChapter] = []) {
        self.name = name
        self.testament = testament
        self.chapters = chapters
    }
}

@Model
final class BibleChapter {
    var number: Int
    var verses: [BibleVerse]
    var book: BibleBook?
    
    init(number: Int, verses: [BibleVerse] = []) {
        self.number = number
        self.verses = verses
    }
}

@Model
final class BibleVerse {
    var number: Int
    var text: String
    var chapter: BibleChapter?
    
    init(number: Int, text: String) {
        self.number = number
        self.text = text
    }
}

enum Testament: String, CaseIterable, Codable {
    case oldTestament = "Antigo Testamento"
    case newTestament = "Novo Testamento"
}

// Helper extension for sample data
extension BibleBook {
    static let sampleBooks: [BibleBook] = [
        BibleBook(name: "Gênesis", testament: .oldTestament),
        BibleBook(name: "Êxodo", testament: .oldTestament),
        BibleBook(name: "Levítico", testament: .oldTestament),
        BibleBook(name: "Números", testament: .oldTestament),
        BibleBook(name: "Deuteronômio", testament: .oldTestament),
        BibleBook(name: "Josué", testament: .oldTestament),
        BibleBook(name: "Juízes", testament: .oldTestament),
        BibleBook(name: "Rute", testament: .oldTestament),
        BibleBook(name: "1 Samuel", testament: .oldTestament),
        BibleBook(name: "2 Samuel", testament: .oldTestament),
        BibleBook(name: "1 Reis", testament: .oldTestament),
        BibleBook(name: "2 Reis", testament: .oldTestament),
        BibleBook(name: "1 Crônicas", testament: .oldTestament),
        BibleBook(name: "2 Crônicas", testament: .oldTestament),
        BibleBook(name: "Esdras", testament: .oldTestament),
        BibleBook(name: "Neemias", testament: .oldTestament),
        BibleBook(name: "Tobias", testament: .oldTestament),
        BibleBook(name: "Judite", testament: .oldTestament),
        BibleBook(name: "Ester", testament: .oldTestament),
        BibleBook(name: "Jó", testament: .oldTestament),
        BibleBook(name: "Salmos", testament: .oldTestament),
        BibleBook(name: "Provérbios", testament: .oldTestament),
        BibleBook(name: "Eclesiastes", testament: .oldTestament),
        BibleBook(name: "Cântico dos Cânticos", testament: .oldTestament),
        BibleBook(name: "Sabedoria", testament: .oldTestament),
        BibleBook(name: "Eclesiástico", testament: .oldTestament),
        BibleBook(name: "Isaías", testament: .oldTestament),
        BibleBook(name: "Jeremias", testament: .oldTestament),
        BibleBook(name: "Lamentações", testament: .oldTestament),
        BibleBook(name: "Baruc", testament: .oldTestament),
        BibleBook(name: "Ezequiel", testament: .oldTestament),
        BibleBook(name: "Daniel", testament: .oldTestament),
        BibleBook(name: "Oséias", testament: .oldTestament),
        BibleBook(name: "Joel", testament: .oldTestament),
        BibleBook(name: "Amós", testament: .oldTestament),
        BibleBook(name: "Abdias", testament: .oldTestament),
        BibleBook(name: "Jonas", testament: .oldTestament),
        BibleBook(name: "Miquéias", testament: .oldTestament),
        BibleBook(name: "Naum", testament: .oldTestament),
        BibleBook(name: "Habacuc", testament: .oldTestament),
        BibleBook(name: "Sofonias", testament: .oldTestament),
        BibleBook(name: "Ageu", testament: .oldTestament),
        BibleBook(name: "Zacarias", testament: .oldTestament),
        BibleBook(name: "Malaquias", testament: .oldTestament),
        BibleBook(name: "Mateus", testament: .newTestament),
        BibleBook(name: "Marcos", testament: .newTestament),
        BibleBook(name: "Lucas", testament: .newTestament),
        BibleBook(name: "João", testament: .newTestament),
        BibleBook(name: "Atos", testament: .newTestament),
        BibleBook(name: "Romanos", testament: .newTestament),
        BibleBook(name: "1 Coríntios", testament: .newTestament),
        BibleBook(name: "2 Coríntios", testament: .newTestament),
        BibleBook(name: "Gálatas", testament: .newTestament),
        BibleBook(name: "Efésios", testament: .newTestament),
        BibleBook(name: "Filipenses", testament: .newTestament),
        BibleBook(name: "Colossenses", testament: .newTestament),
        BibleBook(name: "1 Tessalonicenses", testament: .newTestament),
        BibleBook(name: "2 Tessalonicenses", testament: .newTestament),
        BibleBook(name: "1 Timóteo", testament: .newTestament),
        BibleBook(name: "2 Timóteo", testament: .newTestament),
        BibleBook(name: "Tito", testament: .newTestament),
        BibleBook(name: "Filêmon", testament: .newTestament),
        BibleBook(name: "Hebreus", testament: .newTestament),
        BibleBook(name: "Tiago", testament: .newTestament),
        BibleBook(name: "1 Pedro", testament: .newTestament),
        BibleBook(name: "2 Pedro", testament: .newTestament),
        BibleBook(name: "1 João", testament: .newTestament),
        BibleBook(name: "2 João", testament: .newTestament),
        BibleBook(name: "3 João", testament: .newTestament),
        BibleBook(name: "Judas", testament: .newTestament),
        BibleBook(name: "Apocalipse", testament: .newTestament)
    ]
}
