import Foundation
import SwiftData

// MARK: - Schema V1 (original schema without relationships)
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [BibleVerseV1.self, VerseNoteV1.self]
    }

    @Model
    final class BibleVerseV1 {
        var bookName: String
        var chapterNumber: Int
        var verseNumber: Int
        var text: String
        var isHighlighted: Bool = false

        init(bookName: String, chapterNumber: Int, verseNumber: Int, text: String) {
            self.bookName = bookName
            self.chapterNumber = chapterNumber
            self.verseNumber = verseNumber
            self.text = text
        }
    }

    @Model
    final class VerseNoteV1 {
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
}

// MARK: - Schema V2 (adds BibleVerse <-> VerseNote relationship)
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [BibleVerse.self, VerseNote.self]
    }
}

// MARK: - Migration Plan
enum BibleMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    ) { context in
        // Lightweight migration handles adding the new relationship columns.
        // This willMigrate block runs before the schema change.
    } didMigrate: { context in
        // After migration: link existing VerseNote records to their BibleVerse
        // by matching on bookName + chapterNumber + verseNumber.
        let notes = try context.fetch(FetchDescriptor<VerseNote>())

        for note in notes where note.verse == nil {
            let book = note.bookName
            let chapter = note.chapterNumber
            let verseNum = note.verseNumber
            let descriptor = FetchDescriptor<BibleVerse>(
                predicate: #Predicate { verse in
                    verse.bookName == book &&
                    verse.chapterNumber == chapter &&
                    verse.verseNumber == verseNum
                }
            )
            if let matchingVerse = try context.fetch(descriptor).first {
                note.verse = matchingVerse
            }
        }

        try context.save()
    }
}
