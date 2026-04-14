import Foundation
import SwiftData

@Model
final class BibleVerse {
    #Index<BibleVerse>([\.bookName, \.chapterNumber, \.verseNumber])

    var bookName: String
    var chapterNumber: Int
    var verseNumber: Int
    var text: String
    var isHighlighted: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \VerseNote.verse)
    var notes: [VerseNote] = []

    init(bookName: String, chapterNumber: Int, verseNumber: Int, text: String) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.text = text
    }
}
