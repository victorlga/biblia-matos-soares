import SwiftUI
import SwiftData
import UIKit

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var searchText: String = ""
    @State private var searchResults: [BibleVerse] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Recent searches persistence
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()
    
    // Callback para navegar para um versículo específico no ContentView
    var onNavigateToVerse: ((String, Int, Int) -> Void)?
    
    private var headerFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 20
        case .regular: return 28
        default: return 20
        }
    }
    
    private var bodyFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 18
        case .regular: return 24
        default: return 18
        }
    }
    
    init(onNavigateToVerse: ((String, Int, Int) -> Void)? = nil) {
        self.onNavigateToVerse = onNavigateToVerse
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra superior
                HStack {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text(String(localized: "search.title"))
                        .font(.system(size: headerFontSize, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(
                    Color.black
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1),
                            alignment: .bottom
                        )
                )
                
                // Barra de busca
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    TextField(String(localized: "search.placeholder"), text: $searchText)
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isSearchFieldFocused)
                        .onChange(of: searchText) { _, newValue in
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                guard !Task.isCancelled else { return }
                                await performSearch(query: newValue)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            HapticManager.shared.impact(style: .light)
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Resultados
                if searchText.isEmpty {
                    if recentSearches.isEmpty {
                        Spacer()
                        Text(String(localized: "search.empty_prompt"))
                            .font(.system(size: bodyFontSize, design: .serif))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Spacer()
                    } else {
                        recentSearchesView
                    }
                } else if isSearching {
                    Spacer()
                    ProgressView()
                        .tint(.gray)
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    Text(String(localized: "search.no_results"))
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    // Result count header
                    HStack {
                        Text(searchResults.count >= 100
                            ? String(localized: "search.first_100_results")
                            : "\(searchResults.count) " + String(localized: searchResults.count == 1 ? "search.result_singular" : "search.result_plural"))
                            .font(.system(size: bodyFontSize * 0.8, design: .serif))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { verse in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(verse.bookName), Cap. \(verse.chapterNumber):\(verse.verseNumber)")
                                            .font(.system(size: bodyFontSize * 0.85, weight: .semibold, design: .serif))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    
                                    highlightedText(verse.text, query: searchText)
                                        .font(.system(size: bodyFontSize, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                                .onTapGesture {
                                    HapticManager.shared.impact(style: .light)
                                    openVerse(verse)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Recent Searches
    
    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }
    
    private func addToRecentSearches(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }
    
    private func clearRecentSearches() {
        recentSearchesData = (try? JSONEncoder().encode([String]())) ?? Data()
    }
    
    // MARK: - Recent Searches View
    
    private var recentSearchesView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "search.recent_title"))
                    .font(.system(size: bodyFontSize * 0.9, weight: .semibold, design: .serif))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    HapticManager.shared.impact(style: .light)
                    clearRecentSearches()
                } label: {
                    Text(String(localized: "search.clear"))
                        .font(.system(size: bodyFontSize * 0.8, design: .serif))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(recentSearches, id: \.self) { query in
                        Button {
                            HapticManager.shared.impact(style: .light)
                            searchText = query
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: bodyFontSize * 0.8))
                                    .foregroundColor(.secondary)
                                Text(query)
                                    .font(.system(size: bodyFontSize, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Text Highlighting
    
    private func highlightedText(_ text: String, query: String) -> Text {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return Text(text) }
        
        let lowercasedText = text.lowercased()
        let lowercasedQuery = trimmedQuery.lowercased()
        
        var result = Text("")
        var currentIndex = text.startIndex
        var searchStart = lowercasedText.startIndex
        
        while searchStart < lowercasedText.endIndex {
            guard let range = lowercasedText.range(of: lowercasedQuery, options: [.diacriticInsensitive], range: searchStart..<lowercasedText.endIndex) else {
                break
            }
            
            // Add text before match
            if currentIndex < range.lowerBound {
                result = result + Text(text[currentIndex..<range.lowerBound])
            }
            // Add highlighted match
            result = result + Text(text[range])
                .foregroundColor(.yellow)
                .bold()
            
            currentIndex = range.upperBound
            searchStart = range.upperBound
        }
        
        // Add remaining text
        if currentIndex < text.endIndex {
            result = result + Text(text[currentIndex..<text.endIndex])
        }
        
        return result
    }
    
    @MainActor
    private func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        let container = modelContext.container

        // Fetch PersistentIdentifiers on background context to avoid
        // cross-context access of SwiftData model objects.
        let identifiers: [PersistentIdentifier] = await Task.detached {
            let backgroundContext = ModelContext(container)
            backgroundContext.autosaveEnabled = false

            let descriptor = FetchDescriptor<BibleVerse>(
                predicate: #Predicate { verse in
                    verse.text.localizedStandardContains(trimmedQuery) ||
                    verse.bookName.localizedStandardContains(trimmedQuery)
                }
            )

            do {
                let results = try backgroundContext.fetch(descriptor)
                // Sort in canonical Bible order, then take first 100
                let sorted = results.sorted { v1, v2 in
                    let order1 = BibleData.bookOrderMap[v1.bookName] ?? 999
                    let order2 = BibleData.bookOrderMap[v2.bookName] ?? 999
                    if order1 != order2 { return order1 < order2 }
                    if v1.chapterNumber != v2.chapterNumber { return v1.chapterNumber < v2.chapterNumber }
                    return v1.verseNumber < v2.verseNumber
                }
                return sorted.prefix(100).map { $0.persistentModelID }
            } catch {
                print("Erro ao buscar: \(error.localizedDescription)")
                return []
            }
        }.value

        guard !Task.isCancelled else { return }

        // Re-fetch from main context so model objects are safe to use on main thread
        let mainResults = identifiers.compactMap { id in
            modelContext.model(for: id) as? BibleVerse
        }
        searchResults = mainResults
        isSearching = false
        
        // Save to recent searches if we have results
        if !mainResults.isEmpty {
            addToRecentSearches(trimmedQuery)
        }
    }
    
    private func openVerse(_ verse: BibleVerse) {
        onNavigateToVerse?(verse.bookName, verse.chapterNumber, verse.verseNumber)
        dismiss()
    }
}
