import Foundation
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Export/Import Data Models

struct ExportedData: Codable {
    let exportDate: String
    let appVersion: String
    let noteCount: Int
    let highlightCount: Int
    let notes: [ExportedNote]
    let highlights: [ExportedHighlight]
}

struct ExportedNote: Codable {
    let bookName: String
    let chapterNumber: Int
    let verseNumber: Int
    let noteText: String
    let createdAt: String
    let updatedAt: String
}

struct ExportedHighlight: Codable {
    let bookName: String
    let chapterNumber: Int
    let verseNumber: Int
    let highlightColor: String
}

// MARK: - Import Conflict Resolution
enum ImportConflictResolution {
    case keepExisting
    case overwrite
    case append
}

// MARK: - Export/Import Manager
@MainActor
struct DataExportImportManager {

    // MARK: - Export

    static func exportData(context: ModelContext) -> URL? {
        do {
            // Fetch all notes
            let noteDescriptor = FetchDescriptor<VerseNote>(
                sortBy: [
                    SortDescriptor(\.bookName, comparator: .localizedStandard),
                    SortDescriptor(\.chapterNumber, order: .forward),
                    SortDescriptor(\.verseNumber, order: .forward)
                ]
            )
            let allNotes = try context.fetch(noteDescriptor)

            // Fetch all highlighted verses
            let highlightDescriptor = FetchDescriptor<BibleVerse>(
                predicate: #Predicate { verse in
                    verse.highlightColor != nil
                },
                sortBy: [
                    SortDescriptor(\.bookName, comparator: .localizedStandard),
                    SortDescriptor(\.chapterNumber, order: .forward),
                    SortDescriptor(\.verseNumber, order: .forward)
                ]
            )
            let highlightedVerses = try context.fetch(highlightDescriptor)

            let dateFormatter = ISO8601DateFormatter()

            let exportedNotes = allNotes.map { note in
                ExportedNote(
                    bookName: note.bookName,
                    chapterNumber: note.chapterNumber,
                    verseNumber: note.verseNumber,
                    noteText: note.noteText,
                    createdAt: dateFormatter.string(from: note.createdAt),
                    updatedAt: dateFormatter.string(from: note.updatedAt)
                )
            }

            let exportedHighlights = highlightedVerses.compactMap { verse -> ExportedHighlight? in
                guard let color = verse.highlightColor else { return nil }
                return ExportedHighlight(
                    bookName: verse.bookName,
                    chapterNumber: verse.chapterNumber,
                    verseNumber: verse.verseNumber,
                    highlightColor: color
                )
            }

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

            let exportData = ExportedData(
                exportDate: dateFormatter.string(from: Date()),
                appVersion: appVersion,
                noteCount: exportedNotes.count,
                highlightCount: exportedHighlights.count,
                notes: exportedNotes,
                highlights: exportedHighlights
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(exportData)

            // Write to temp file
            let fileName = "biblia-matos-soares-backup-\(formattedDate()).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: tempURL)

            return tempURL
        } catch {
            print("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    static func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(activityVC, animated: true)
        }
    }

    // MARK: - Import

    static func importData(from url: URL, context: ModelContext, noteConflict: ImportConflictResolution) -> (notes: Int, highlights: Int)? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedData = try decoder.decode(ExportedData.self, from: data)

            let dateFormatter = ISO8601DateFormatter()

            var notesImported = 0
            var highlightsImported = 0

            // Import notes
            for exportedNote in importedData.notes {
                let book = exportedNote.bookName
                let chapter = exportedNote.chapterNumber
                let verseNum = exportedNote.verseNumber

                // Check if a note already exists for this verse
                let descriptor = FetchDescriptor<VerseNote>(
                    predicate: #Predicate { note in
                        note.bookName == book &&
                        note.chapterNumber == chapter &&
                        note.verseNumber == verseNum
                    }
                )
                let existingNotes = try context.fetch(descriptor)

                if let existingNote = existingNotes.first {
                    switch noteConflict {
                    case .keepExisting:
                        continue
                    case .overwrite:
                        existingNote.noteText = exportedNote.noteText
                        existingNote.updatedAt = dateFormatter.date(from: exportedNote.updatedAt) ?? Date()
                        notesImported += 1
                    case .append:
                        existingNote.noteText += "\n---\n" + exportedNote.noteText
                        existingNote.updatedAt = Date()
                        notesImported += 1
                    }
                } else {
                    let newNote = VerseNote(
                        bookName: exportedNote.bookName,
                        chapterNumber: exportedNote.chapterNumber,
                        verseNumber: exportedNote.verseNumber,
                        noteText: exportedNote.noteText
                    )
                    newNote.createdAt = dateFormatter.date(from: exportedNote.createdAt) ?? Date()
                    newNote.updatedAt = dateFormatter.date(from: exportedNote.updatedAt) ?? Date()

                    // Link to verse if possible
                    let verseDescriptor = FetchDescriptor<BibleVerse>(
                        predicate: #Predicate { verse in
                            verse.bookName == book &&
                            verse.chapterNumber == chapter &&
                            verse.verseNumber == verseNum
                        }
                    )
                    if let matchingVerse = try context.fetch(verseDescriptor).first {
                        newNote.verse = matchingVerse
                    }

                    context.insert(newNote)
                    notesImported += 1
                }
            }

            // Import highlights
            for exportedHighlight in importedData.highlights {
                let book = exportedHighlight.bookName
                let chapter = exportedHighlight.chapterNumber
                let verseNum = exportedHighlight.verseNumber

                let descriptor = FetchDescriptor<BibleVerse>(
                    predicate: #Predicate { verse in
                        verse.bookName == book &&
                        verse.chapterNumber == chapter &&
                        verse.verseNumber == verseNum
                    }
                )

                if let verse = try context.fetch(descriptor).first {
                    // Only set highlight if not already highlighted
                    if verse.highlightColor == nil {
                        verse.highlightColor = exportedHighlight.highlightColor
                        highlightsImported += 1
                    }
                }
            }

            try context.save()
            return (notesImported, highlightsImported)
        } catch {
            print("Import failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - JSON Document for file picker
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let fileData = configuration.file.regularFileContents {
            self.data = fileData
        } else {
            self.data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
