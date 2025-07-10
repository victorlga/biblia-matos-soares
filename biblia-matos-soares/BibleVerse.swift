//
//  BibleVerse.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 12/06/25.
//

import Foundation
import SwiftData

@Model
final class BibleVerse {
    var bookName: String
    var chapterNumber: Int
    var verseNumber: Int
    var text: String

    init(bookName: String, chapterNumber: Int, verseNumber: Int, text: String) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.text = text
    }
}
