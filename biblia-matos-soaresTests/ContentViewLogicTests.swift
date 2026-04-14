import Testing
import SwiftData
@testable import biblia_matos_soares

@MainActor
struct ContentViewLogicTests {

    @Test func goToNextChapterAdvancesToNextBook() {
        let vm = ContentViewModel()
        // Set to last chapter of Gênesis (50 chapters)
        vm.selectedBook = "Gênesis"
        vm.selectedChapter = 50

        vm.goToNextChapter()

        #expect(vm.selectedBook == "Êxodo")
        #expect(vm.selectedChapter == 1)
    }

    @Test func goToNextChapterFromApocalipseWrapsToGenesis() {
        let vm = ContentViewModel()
        vm.selectedBook = "Apocalipse"
        vm.selectedChapter = 22 // last chapter

        vm.goToNextChapter()

        #expect(vm.selectedBook == "Gênesis")
        #expect(vm.selectedChapter == 1)
    }

    @Test func goToPreviousChapterFromChapter1GoesToPreviousBook() {
        let vm = ContentViewModel()
        vm.selectedBook = "Êxodo"
        vm.selectedChapter = 1

        vm.goToPreviousChapter()

        #expect(vm.selectedBook == "Gênesis")
        #expect(vm.selectedChapter == 50) // last chapter of Gênesis
    }

    @Test func goToPreviousChapterFromGenesisWrapsToApocalipse() {
        let vm = ContentViewModel()
        vm.selectedBook = "Gênesis"
        vm.selectedChapter = 1

        vm.goToPreviousChapter()

        #expect(vm.selectedBook == "Apocalipse")
        #expect(vm.selectedChapter == 22) // last chapter of Apocalipse
    }

    @Test func groupConsecutiveHighlightedVersesGroupsCorrectly() throws {
        let schema = Schema([BibleVerse.self, VerseNote.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Create test verses with alternating highlights
        let v1 = BibleVerse(bookName: "Test", chapterNumber: 1, verseNumber: 1, text: "A")
        v1.isHighlighted = false
        let v2 = BibleVerse(bookName: "Test", chapterNumber: 1, verseNumber: 2, text: "B")
        v2.isHighlighted = false
        let v3 = BibleVerse(bookName: "Test", chapterNumber: 1, verseNumber: 3, text: "C")
        v3.isHighlighted = true
        let v4 = BibleVerse(bookName: "Test", chapterNumber: 1, verseNumber: 4, text: "D")
        v4.isHighlighted = true
        let v5 = BibleVerse(bookName: "Test", chapterNumber: 1, verseNumber: 5, text: "E")
        v5.isHighlighted = false

        for v in [v1, v2, v3, v4, v5] { context.insert(v) }

        let vm = ContentViewModel()
        let groups = vm.groupConsecutiveHighlightedVerses([v1, v2, v3, v4, v5])

        #expect(groups.count == 3)
        #expect(groups[0].isHighlighted == false)
        #expect(groups[0].verses.count == 2)
        #expect(groups[1].isHighlighted == true)
        #expect(groups[1].verses.count == 2)
        #expect(groups[2].isHighlighted == false)
        #expect(groups[2].verses.count == 1)
    }

    @Test func goToNextChapterWithinSameBook() {
        let vm = ContentViewModel()
        vm.selectedBook = "Gênesis"
        vm.selectedChapter = 1

        vm.goToNextChapter()

        #expect(vm.selectedBook == "Gênesis")
        #expect(vm.selectedChapter == 2)
    }

    @Test func goToPreviousChapterWithinSameBook() {
        let vm = ContentViewModel()
        vm.selectedBook = "Gênesis"
        vm.selectedChapter = 5

        vm.goToPreviousChapter()

        #expect(vm.selectedBook == "Gênesis")
        #expect(vm.selectedChapter == 4)
    }
}
