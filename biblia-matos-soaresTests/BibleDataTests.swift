import Testing
@testable import biblia_matos_soares

struct BibleDataTests {

    @Test func orderedBookNamesHas73Entries() {
        #expect(BibleData.orderedBookNames.count == 73)
    }

    @Test func firstBookIsGenesis() {
        #expect(BibleData.orderedBookNames.first == "Gênesis")
    }

    @Test func lastBookIsApocalipse() {
        #expect(BibleData.orderedBookNames.last == "Apocalipse")
    }

    @Test func numberOfChaptersReturnsCorrectValues() {
        #expect(BibleData.numberOfChapters(forBook: "Gênesis") == 50)
        #expect(BibleData.numberOfChapters(forBook: "Salmos") == 150)
        #expect(BibleData.numberOfChapters(forBook: "Apocalipse") == 22)
        #expect(BibleData.numberOfChapters(forBook: "Abdias") == 1)
    }

    @Test func numberOfChaptersReturnsNilForUnknown() {
        #expect(BibleData.numberOfChapters(forBook: "LivroInexistente") == nil)
    }

    @Test func bookOrderMapAndChapterCountsHaveSameKeys() {
        let orderKeys = Set(BibleData.bookOrderMap.keys)
        let chapterKeys = Set(BibleData.bookChapterCounts.keys)
        #expect(orderKeys == chapterKeys)
    }
}
