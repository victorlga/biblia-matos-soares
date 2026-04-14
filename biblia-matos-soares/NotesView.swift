import SwiftUI
import SwiftData
import UIKit

// Estrutura auxiliar para agrupar notas por capítulo
struct GroupedNoteChapter: Identifiable {
    let id = UUID()
    let bookName: String
    let chapterNumber: Int
    let notes: [VerseNote]
}

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Query private var allNotes: [VerseNote]
    
    @State private var noteToEdit: VerseNote?
    
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
        _allNotes = Query(
            sort: [
                SortDescriptor(\.bookName, comparator: .localizedStandard),
                SortDescriptor(\.chapterNumber, order: .forward),
                SortDescriptor(\.verseNumber, order: .forward)
            ]
        )
    }
    
    // Ordena as notas com base na ordem da Bíblia
    private var sortedNotes: [VerseNote] {
        allNotes.sorted { n1, n2 in
            let order1 = BibleData.bookOrderMap[n1.bookName] ?? 999
            let order2 = BibleData.bookOrderMap[n2.bookName] ?? 999
            
            if order1 != order2 {
                return order1 < order2
            } else if n1.chapterNumber != n2.chapterNumber {
                return n1.chapterNumber < n2.chapterNumber
            } else {
                return n1.verseNumber < n2.verseNumber
            }
        }
    }
    
    // Agrupa notas por livro e capítulo
    private var groupedNotes: [GroupedNoteChapter] {
        var groups: [GroupedNoteChapter] = []
        var currentBook: String?
        var currentChapter: Int?
        var notes: [VerseNote] = []
        
        for note in sortedNotes {
            if note.bookName != currentBook || note.chapterNumber != currentChapter {
                if let book = currentBook, let chapter = currentChapter, !notes.isEmpty {
                    groups.append(GroupedNoteChapter(bookName: book, chapterNumber: chapter, notes: notes))
                }
                currentBook = note.bookName
                currentChapter = note.chapterNumber
                notes = [note]
            } else {
                notes.append(note)
            }
        }
        
        if let book = currentBook, let chapter = currentChapter, !notes.isEmpty {
            groups.append(GroupedNoteChapter(bookName: book, chapterNumber: chapter, notes: notes))
        }
        
        return groups
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
                    
                    Text("Notas")
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
                
                if sortedNotes.isEmpty {
                    Spacer()
                    Text("Nenhuma nota criada. Toque e segure um versículo para criar uma nota.")
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedNotes) { group in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Header do capítulo
                                    HStack {
                                        Text("\(group.bookName), \(group.chapterNumber)")
                                            .font(.system(size: bodyFontSize * 1.1, weight: .bold, design: .serif))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                    
                                    // Notas do capítulo
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(group.notes) { note in
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Text("\("Versículo") \(note.verseNumber)")
                                                        .font(.system(size: bodyFontSize * 0.85, weight: .semibold, design: .serif))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Spacer()
                                                    
                                                    Text(formatDate(note.updatedAt))
                                                        .font(.system(size: bodyFontSize * 0.75, design: .serif))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Text(note.noteText)
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
                                            .contextMenu {
                                                Button {
                                                    HapticManager.shared.impact(style: .light)
                                                    openVerse(note)
                                                } label: {
                                                    Label("Abrir Versículo", systemImage: "book.closed")
                                                }

                                                Button {
                                                    HapticManager.shared.impact(style: .light)
                                                    noteToEdit = note
                                                } label: {
                                                    Label("Editar", systemImage: "pencil")
                                                }

                                                Button(role: .destructive) {
                                                    HapticManager.shared.notification(type: .warning)
                                                    deleteNote(note)
                                                } label: {
                                                    Label("Excluir", systemImage: "trash")
                                                }
                                            }
                                            .onTapGesture {
                                                HapticManager.shared.impact(style: .light)
                                                noteToEdit = note
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .sheet(item: $noteToEdit) { note in
            NoteEditorView(existingNote: note)
        }
    }
    
    private func openVerse(_ note: VerseNote) {
        onNavigateToVerse?(note.bookName, note.chapterNumber, note.verseNumber)
        dismiss()
    }
    
    private func deleteNote(_ note: VerseNote) {
        modelContext.delete(note)
        do {
            try modelContext.save()
        } catch {
            print("Erro ao excluir nota: \(error.localizedDescription)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
