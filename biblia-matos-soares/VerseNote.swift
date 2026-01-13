import Foundation
import SwiftData

@Model
final class VerseNote {
    var bookName: String
    var chapterNumber: Int
    var verseNumber: Int
    var noteText: String
    var createdAt: Date
    var updatedAt: Date

    init(bookName: String, chapterNumber: Int, verseNumber: Int, noteText: String) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.noteText = noteText
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
