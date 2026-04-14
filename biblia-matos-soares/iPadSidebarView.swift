import SwiftUI

/// Sidebar view for iPad split-view layout.
/// Shows books grouped by Old Testament / New Testament.
struct iPadSidebarView: View {
    @Binding var selectedBook: String
    @Binding var selectedChapter: Int
    var onBookSelected: ((String) -> Void)?

    private let oldTestamentBooks: [String] = {
        let otOrder = BibleData.orderedBookNames.prefix(while: { $0 != "São Mateus" })
        return Array(otOrder)
    }()

    private let newTestamentBooks: [String] = {
        let allBooks = BibleData.orderedBookNames
        guard let ntStart = allBooks.firstIndex(of: "São Mateus") else { return [] }
        return Array(allBooks[ntStart...])
    }()

    var body: some View {
        List(selection: Binding(
            get: { selectedBook },
            set: { newValue in
                if let book = newValue {
                    selectedBook = book
                    selectedChapter = 1
                    onBookSelected?(book)
                }
            }
        )) {
            Section("Antigo Testamento") {
                ForEach(oldTestamentBooks, id: \.self) { book in
                    bookRow(book)
                }
            }

            Section("Novo Testamento") {
                ForEach(newTestamentBooks, id: \.self) { book in
                    bookRow(book)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Livros")
        .preferredColorScheme(.dark)
    }

    private func bookRow(_ book: String) -> some View {
        HStack {
            Text(book)
                .font(.system(size: 16, design: .serif))

            Spacer()

            if let chapters = BibleData.bookChapterCounts[book] {
                Text("\(chapters) cap.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(.secondary)
            }
        }
        .tag(book)
    }
}
