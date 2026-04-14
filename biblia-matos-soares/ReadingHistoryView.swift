import SwiftUI

struct ReadingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage("readingHistory") private var readingHistoryData: Data = Data()

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

    private var historyEntries: [(bookName: String, chapterNumber: Int)] {
        guard let decoded = try? JSONDecoder().decode([String].self, from: readingHistoryData) else {
            return []
        }
        return decoded.compactMap { entry in
            let parts = entry.split(separator: "|")
            guard parts.count == 2,
                  let chapter = Int(parts[1]) else { return nil }
            return (bookName: String(parts[0]), chapterNumber: chapter)
        }
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

                    Text(String(localized: "history.title"))
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

                if historyEntries.isEmpty {
                    Spacer()
                    Text(String(localized: "history.empty"))
                        .font(.system(size: bodyFontSize, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(historyEntries.enumerated()), id: \.offset) { _, entry in
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: bodyFontSize * 0.85))
                                        .foregroundColor(.secondary)

                                    Text("\(entry.bookName), Cap. \(entry.chapterNumber)")
                                        .font(.system(size: bodyFontSize, design: .serif))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: bodyFontSize * 0.7))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                                .onTapGesture {
                                    HapticManager.shared.impact(style: .light)
                                    onNavigateToVerse?(entry.bookName, entry.chapterNumber, 1)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }
}
