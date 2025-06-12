//
//  BibleChapter.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 12/06/25.
//

import Foundation
import SwiftData

@Model
class BibleChapter {
    @Attribute(.unique) var id: UUID = UUID()  // id único
    var number: Int
    @Relationship var book: BibleBook
    var verses: [BibleVerse] = []

    init(number: Int, book: BibleBook) {
        self.number = number
        self.book = book
    }
}
