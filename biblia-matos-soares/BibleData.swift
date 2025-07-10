//
//  BibleData.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 10/07/25.
//

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
