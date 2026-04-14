import Foundation
import SwiftData

@Model
final class ReadingProgress {
    var bookName: String
    var chapterNumber: Int
    var completedAt: Date

    init(bookName: String, chapterNumber: Int, completedAt: Date = Date()) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.completedAt = completedAt
    }
}
