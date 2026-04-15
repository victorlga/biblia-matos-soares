import SwiftUI
import SwiftData
import AVFoundation
import UIKit

@MainActor
@Observable
class ContentViewModel {
    // MARK: - Persisted state
    @ObservationIgnored
    @AppStorage("lastSelectedBook") var storedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    @ObservationIgnored
    @AppStorage("lastSelectedChapter") var storedChapter: Int = 1
    @ObservationIgnored
    @AppStorage("readingHistory") var readingHistoryData: Data = Data()

    // MARK: - Navigation state
    var selectedBook: String = BibleData.orderedBookNames.first ?? "Gênesis"
    var selectedChapter: Int = 1
    /// When true, the onChange(of: selectedBook) handler should NOT reset chapter to 1.
    var suppressChapterReset: Bool = false

    // MARK: - TTS
    var speechSynthesizer = AVSpeechSynthesizer()

    // MARK: - Verse grouping
    struct VerseGroup: Identifiable {
        let id = UUID()
        let verses: [BibleVerse]
        let highlightColor: String?
    }

    // MARK: - Initialization
    func restoreFromStorage() {
        selectedBook = storedBook
        selectedChapter = storedChapter
        updateReadingHistory()
    }

    // MARK: - Verse fetching
    func fetchVerses(context: ModelContext) -> [BibleVerse] {
        let book = selectedBook
        let chapter = selectedChapter
        do {
            let descriptor = FetchDescriptor<BibleVerse>(
                predicate: #Predicate { verse in
                    verse.bookName == book && verse.chapterNumber == chapter
                },
                sortBy: [SortDescriptor(\.verseNumber, order: .forward)]
            )
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    func fetchVerseNumbersWithNotes(context: ModelContext) -> Set<Int> {
        let book = selectedBook
        let chapter = selectedChapter
        do {
            let descriptor = FetchDescriptor<VerseNote>(
                predicate: #Predicate { note in
                    note.bookName == book && note.chapterNumber == chapter
                }
            )
            let notes = try context.fetch(descriptor)
            return Set(notes.map(\.verseNumber))
        } catch {
            return []
        }
    }

    func findNoteForVerse(_ verse: BibleVerse, context: ModelContext) -> VerseNote? {
        // Use the relationship if notes are already loaded
        if !verse.notes.isEmpty {
            return verse.notes.first
        }
        // Fallback to query for backward compatibility with un-migrated data
        let book = verse.bookName
        let chapter = verse.chapterNumber
        let verseNum = verse.verseNumber
        do {
            let descriptor = FetchDescriptor<VerseNote>(
                predicate: #Predicate { note in
                    note.bookName == book && note.chapterNumber == chapter && note.verseNumber == verseNum
                }
            )
            return try context.fetch(descriptor).first
        } catch {
            #if DEBUG
            print("Erro ao buscar nota: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    // MARK: - Chapter navigation
    func goToPreviousChapter() {
        let currentBookIndex = BibleData.orderedBookNames.firstIndex(of: selectedBook) ?? 0

        if selectedChapter > 1 {
            selectedChapter -= 1
        } else if currentBookIndex > 0 {
            let previousBookName = BibleData.orderedBookNames[currentBookIndex - 1]
            suppressChapterReset = true
            selectedBook = previousBookName
            selectedChapter = BibleData.numberOfChapters(forBook: previousBookName) ?? 1
        } else {
            suppressChapterReset = true
            selectedBook = BibleData.orderedBookNames.last ?? "Apocalipse"
            selectedChapter = BibleData.numberOfChapters(forBook: selectedBook) ?? 1
        }
    }

    func goToNextChapter() {
        let currentBookIndex = BibleData.orderedBookNames.firstIndex(of: selectedBook) ?? 0
        let numberOfChaptersInCurrentBook = BibleData.numberOfChapters(forBook: selectedBook) ?? 1

        if selectedChapter < numberOfChaptersInCurrentBook {
            selectedChapter += 1
        } else if currentBookIndex < BibleData.orderedBookNames.count - 1 {
            let nextBookName = BibleData.orderedBookNames[currentBookIndex + 1]
            selectedBook = nextBookName
            selectedChapter = 1
        } else {
            selectedBook = BibleData.orderedBookNames.first ?? "Gênesis"
            selectedChapter = 1
        }
    }

    // MARK: - Text-to-speech
    func readCurrentChapter(verses: [BibleVerse], rate: Float) {
        let voice = SpeechHelper.bestAvailableVoice()
        for verse in verses {
            let utterance = AVSpeechUtterance(string: verse.text)
            utterance.voice = voice
            utterance.rate = rate
            utterance.pitchMultiplier = 1.05
            utterance.preUtteranceDelay = 0.3
            speechSynthesizer.speak(utterance)
        }
    }

    // MARK: - Highlight
    func setHighlightColor(_ color: String?, for verse: BibleVerse, context: ModelContext) {
        verse.highlightColor = color
        verse.isHighlighted = false // legacy field, always false in V3
        HapticManager.shared.impact(style: .medium)

        do {
            try context.save()
        } catch {
            #if DEBUG
            print("Failed to save highlight change: \(error.localizedDescription)")
            #endif
        }
    }

    func removeHighlight(for verse: BibleVerse, context: ModelContext) {
        setHighlightColor(nil, for: verse, context: context)
    }

    // MARK: - Clipboard
    func copyVerseReference(_ verse: BibleVerse) {
        let reference = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber)"
        UIPasteboard.general.string = reference
        HapticManager.shared.notification(type: .success)
    }

    func copyVerseWithText(_ verse: BibleVerse) {
        let fullText = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber) - \(verse.text)"
        UIPasteboard.general.string = fullText
        HapticManager.shared.notification(type: .success)
    }

    // MARK: - Share
    func shareVerse(_ verse: BibleVerse) {
        let shareText = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber) - \(verse.text)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    // MARK: - Reading history
    func updateReadingHistory() {
        let historyItem = "\(selectedBook)|\(selectedChapter)"
        var history: [String] = []

        if let decoded = try? JSONDecoder().decode([String].self, from: readingHistoryData) {
            history = decoded
        }

        // Remove if already exists
        history.removeAll { $0 == historyItem }
        // Add to front
        history.insert(historyItem, at: 0)
        // Keep only last 10
        if history.count > 10 {
            history = Array(history.prefix(10))
        }

        if let encoded = try? JSONEncoder().encode(history) {
            readingHistoryData = encoded
        }
    }

    // MARK: - Verse grouping
    func groupConsecutiveHighlightedVerses(_ verses: [BibleVerse]) -> [VerseGroup] {
        var groups: [VerseGroup] = []
        var currentGroup: [BibleVerse] = []
        var currentColor: String? = nil

        for verse in verses {
            if currentGroup.isEmpty {
                currentGroup.append(verse)
                currentColor = verse.highlightColor
            } else if verse.highlightColor == currentColor {
                currentGroup.append(verse)
            } else {
                groups.append(VerseGroup(verses: currentGroup, highlightColor: currentColor))
                currentGroup = [verse]
                currentColor = verse.highlightColor
            }
        }

        if !currentGroup.isEmpty {
            groups.append(VerseGroup(verses: currentGroup, highlightColor: currentColor))
        }

        return groups
    }

    // MARK: - Persistence sync
    func syncBookToStorage() {
        storedBook = selectedBook
        storedChapter = selectedChapter
        updateReadingHistory()
    }

    func syncChapterToStorage() {
        storedChapter = selectedChapter
        updateReadingHistory()
    }
}
