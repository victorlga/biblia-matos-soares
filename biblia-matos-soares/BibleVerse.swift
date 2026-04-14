import Foundation
import SwiftUI
import SwiftData

@Model
final class BibleVerse {
    #Index<BibleVerse>([\.bookName, \.chapterNumber, \.verseNumber])

    var bookName: String
    var chapterNumber: Int
    var verseNumber: Int
    var text: String

    /// Legacy stored property kept for migration. After V2→V3 migration runs,
    /// this is always false and highlightColor is the source of truth.
    var isHighlighted: Bool = false

    /// nil = not highlighted; "yellow", "green", "blue", "pink" = highlight color.
    var highlightColor: String?

    @Relationship(deleteRule: .cascade, inverse: \VerseNote.verse)
    var notes: [VerseNote] = []

    init(bookName: String, chapterNumber: Int, verseNumber: Int, text: String) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.text = text
    }

    /// Returns the SwiftUI color for the current highlight, with reduced opacity.
    var highlightSwiftUIColor: Color? {
        guard let highlightColor else { return nil }
        switch highlightColor {
        case "yellow": return Color.yellow.opacity(0.3)
        case "green": return Color.green.opacity(0.3)
        case "blue": return Color.blue.opacity(0.3)
        case "pink": return Color.pink.opacity(0.3)
        default: return Color.yellow.opacity(0.3)
        }
    }

    /// Available highlight color options.
    static let availableColors: [(name: String, color: Color)] = [
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("pink", .pink)
    ]
}
