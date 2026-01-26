import SwiftUI
import SwiftData
import UIKit

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var searchText: String = ""
    @State private var searchResults: [BibleVerse] = []
    
    // Callback para navegar para um versículo específico no ContentView
    var onNavigateToVerse: ((String, Int) -> Void)?
    
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
    
    init(onNavigateToVerse: ((String, Int) -> Void)? = nil) {
        self.onNavigateToVerse = onNavigateToVerse
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra superior
                HStack {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("Buscar")
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
                    
                    TextField("Buscar versículos...", text: $searchText)
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
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
                    Spacer()
                    Text("Digite para buscar versículos")
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    Text("Nenhum resultado encontrado")
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
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
                                    
                                    Text(verse.text)
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
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    openVerse(verse)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        
        do {
            let descriptor = FetchDescriptor<BibleVerse>(
                predicate: #Predicate { verse in
                    verse.text.localizedStandardContains(trimmedQuery)
                },
                sortBy: [
                    SortDescriptor(\.bookName, comparator: .localizedStandard),
                    SortDescriptor(\.chapterNumber, order: .forward),
                    SortDescriptor(\.verseNumber, order: .forward)
                ]
            )
            
            // Limitar resultados para performance (primeiros 100)
            var results = try modelContext.fetch(descriptor)
            if results.count > 100 {
                results = Array(results.prefix(100))
            }
            
            searchResults = results
        } catch {
            print("Erro ao buscar: \(error.localizedDescription)")
            searchResults = []
        }
    }
    
    private func openVerse(_ verse: BibleVerse) {
        onNavigateToVerse?(verse.bookName, verse.chapterNumber)
        dismiss()
    }
}
