//
//  BibleVerse.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 12/06/25.
//

import Foundation
import SwiftData

@Model
class BibleVerse {
    @Attribute(.unique) var id: UUID = UUID()  // id único
    var number: Int
    var text: String
    @Relationship var chapter: BibleChapter

    init(number: Int, text: String, chapter: BibleChapter) {
        self.number = number
        self.text = text
        self.chapter = chapter
    }
}
