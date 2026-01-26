import SwiftUI
import SwiftData
import UIKit

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let verse: BibleVerse?
    let existingNote: VerseNote?
    
    @State private var noteText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
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
    
    init(verse: BibleVerse? = nil, existingNote: VerseNote? = nil) {
        self.verse = verse
        self.existingNote = existingNote
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
                        Text("Cancelar")
                            .font(.system(size: bodyFontSize, design: .serif))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(existingNote != nil ? "Editar Nota" : "Nova Nota")
                        .font(.system(size: headerFontSize, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        saveNote()
                    } label: {
                        Text("Salvar")
                            .font(.system(size: bodyFontSize, weight: .semibold, design: .serif))
                            .foregroundColor(.white)
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespaces).isEmpty)
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
                
                // Referência do versículo (se houver)
                if let verse = verse {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(verse.bookName), Cap. \(verse.chapterNumber):\(verse.verseNumber)")
                            .font(.system(size: bodyFontSize * 0.85, weight: .semibold, design: .serif))
                            .foregroundColor(.secondary)
                        
                        Text(verse.text)
                            .font(.system(size: bodyFontSize * 0.9, design: .serif))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .padding()
                }
                
                // Editor de texto
                TextEditor(text: $noteText)
                    .font(.system(size: bodyFontSize, design: .serif))
                    .foregroundColor(.primary)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .focused($isTextFieldFocused)
                    .padding()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let existingNote = existingNote {
                noteText = existingNote.noteText
            }
            isTextFieldFocused = true
        }
    }
    
    private func saveNote() {
        let trimmedText = noteText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }

        // Haptic feedback for save action
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        if let existingNote = existingNote {
            // Editar nota existente
            existingNote.noteText = trimmedText
            existingNote.updatedAt = Date()
        } else if let verse = verse {
            // Criar nova nota para um versículo
            let newNote = VerseNote(
                bookName: verse.bookName,
                chapterNumber: verse.chapterNumber,
                verseNumber: verse.verseNumber,
                noteText: trimmedText
            )
            modelContext.insert(newNote)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Erro ao salvar nota: \(error.localizedDescription)")
        }
    }
}
