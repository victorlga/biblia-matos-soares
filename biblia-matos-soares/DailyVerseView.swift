import SwiftUI
import SwiftData
import UIKit

struct DailyVerseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var dailyVerse: BibleVerse?

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

                    Text("Versículo do Dia")
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

                Spacer()

                if let verse = dailyVerse {
                    VStack(spacing: 24) {
                        // Verse text
                        Text("\u{201C}\(verse.text)\u{201D}")
                            .font(.system(size: bodyFontSize * 1.15, weight: .regular, design: .serif))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        // Reference
                        Text("\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber)")
                            .font(.system(size: bodyFontSize * 0.9, weight: .semibold, design: .serif))
                            .foregroundColor(.secondary)

                        // Action buttons
                        HStack(spacing: 32) {
                            // Share button
                            Button {
                                HapticManager.shared.impact(style: .light)
                                shareVerse(verse)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 22))
                                    Text("Compartilhar")
                                        .font(.system(size: 13, design: .serif))
                                }
                                .foregroundColor(.white)
                            }

                            // Bookmark button
                            Button {
                                HapticManager.shared.impact(style: .medium)
                                toggleHighlight(for: verse)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: verse.highlightColor != nil ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 22))
                                    Text(verse.highlightColor != nil ? "Marcado" : "Marcar")
                                        .font(.system(size: 13, design: .serif))
                                }
                                .foregroundColor(verse.highlightColor != nil ? .yellow : .white)
                            }

                            // Navigate button
                            Button {
                                HapticManager.shared.impact(style: .light)
                                onNavigateToVerse?(verse.bookName, verse.chapterNumber, verse.verseNumber)
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 22))
                                    Text("Abrir")
                                        .font(.system(size: 13, design: .serif))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 24)
                } else {
                    ProgressView()
                        .tint(.gray)
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .task {
            loadDailyVerse()
        }
    }

    private func loadDailyVerse() {
        do {
            let descriptor = FetchDescriptor<BibleVerse>(
                sortBy: [
                    SortDescriptor(\.bookName, comparator: .localizedStandard),
                    SortDescriptor(\.chapterNumber, order: .forward),
                    SortDescriptor(\.verseNumber, order: .forward)
                ]
            )
            let allVerses = try modelContext.fetch(descriptor)
            guard !allVerses.isEmpty else { return }

            // Deterministic selection based on current date
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let year = calendar.component(.year, from: Date())
            let seed = dayOfYear + year * 366
            let index = seed % allVerses.count

            dailyVerse = allVerses[index]
        } catch {
            print("Erro ao carregar versículo do dia: \(error.localizedDescription)")
        }
    }

    private func shareVerse(_ verse: BibleVerse) {
        let shareText = "\(verse.bookName) \(verse.chapterNumber):\(verse.verseNumber) - \(verse.text)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    private func toggleHighlight(for verse: BibleVerse) {
        if verse.highlightColor != nil {
            verse.highlightColor = nil
        } else {
            verse.highlightColor = "yellow"
        }
        verse.isHighlighted = false // legacy field
        do {
            try modelContext.save()
        } catch {
            print("Erro ao salvar destaque: \(error.localizedDescription)")
        }
    }
}
