import SwiftUI
import SwiftData

struct ReadingProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query private var allProgress: [ReadingProgress]

    @State private var expandedBooks: Set<String> = []

    var onNavigateToVerse: ((String, Int, Int) -> Void)?

    init(onNavigateToVerse: ((String, Int, Int) -> Void)? = nil) {
        self.onNavigateToVerse = onNavigateToVerse
        _allProgress = Query(
            sort: [SortDescriptor(\.completedAt, order: .reverse)]
        )
    }

    private var headerFontSize: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 20
        case .regular: return 28
        default: return 20
        }
    }

    // Total chapters in the Bible
    private var totalChapters: Int {
        BibleData.bookChapterCounts.values.reduce(0, +)
    }

    // Unique read chapters
    private var readChapters: Set<String> {
        Set(allProgress.map { "\($0.bookName)|\($0.chapterNumber)" })
    }

    private var readChapterCount: Int {
        readChapters.count
    }

    private var progressFraction: Double {
        guard totalChapters > 0 else { return 0 }
        return Double(readChapterCount) / Double(totalChapters)
    }

    // Streak: consecutive days with at least one chapter read
    private var currentStreak: Int {
        let calendar = Calendar.current
        var dates: Set<DateComponents> = []
        for entry in allProgress {
            let components = calendar.dateComponents([.year, .month, .day], from: entry.completedAt)
            dates.insert(components)
        }

        guard !dates.isEmpty else { return 0 }

        let sortedDates = dates.compactMap { calendar.date(from: $0) }.sorted(by: >)
        guard let mostRecent = sortedDates.first else { return 0 }

        // Check if the most recent date is today or yesterday
        let today = calendar.startOfDay(for: Date())
        let mostRecentDay = calendar.startOfDay(for: mostRecent)

        let daysDiff = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0
        if daysDiff > 1 { return 0 }

        var streak = 1
        for i in 1..<sortedDates.count {
            let current = calendar.startOfDay(for: sortedDates[i])
            let previous = calendar.startOfDay(for: sortedDates[i - 1])
            let diff = calendar.dateComponents([.day], from: current, to: previous).day ?? 0
            if diff == 1 {
                streak += 1
            } else if diff > 1 {
                break
            }
            // diff == 0 means same day, skip
        }
        return streak
    }

    // Chapters read per book
    private func readChaptersForBook(_ bookName: String) -> Set<Int> {
        Set(allProgress.filter { $0.bookName == bookName }.map(\.chapterNumber))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Text(String(localized: "progress.title"))
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

                ScrollView {
                    VStack(spacing: 24) {
                        // Overall progress card
                        overallProgressCard()

                        // Streak card
                        streakCard()

                        // Per-book progress
                        perBookProgress()
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Overall Progress Card
    private func overallProgressCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "progress.overall"))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(readChapterCount) / \(totalChapters)")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progressFraction)
                .tint(.green)
                .scaleEffect(y: 2)

            Text(String(format: String(localized: "progress.completed_percent"), Int(progressFraction * 100)))
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Streak Card
    private func streakCard() -> some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(currentStreak > 0 ? .orange : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: currentStreak == 1 ? String(localized: "progress.streak_singular") : String(localized: "progress.streak_plural"), currentStreak))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)

                Text(String(localized: "progress.streak_label"))
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Per-Book Progress
    private func perBookProgress() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "progress.per_book"))
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(.primary)

            ForEach(BibleData.orderedBookNames, id: \.self) { bookName in
                let totalBookChapters = BibleData.bookChapterCounts[bookName] ?? 1
                let readSet = readChaptersForBook(bookName)
                let readCount = readSet.count

                VStack(spacing: 0) {
                    Button {
                        HapticManager.shared.impact(style: .light)
                        if expandedBooks.contains(bookName) {
                            expandedBooks.remove(bookName)
                        } else {
                            expandedBooks.insert(bookName)
                        }
                    } label: {
                        HStack {
                            Text(bookName)
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Text("\(readCount)/\(totalBookChapters)")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(.secondary)

                            Image(systemName: expandedBooks.contains(bookName) ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    }

                    if readCount > 0 {
                        ProgressView(value: Double(readCount), total: Double(totalBookChapters))
                            .tint(.green)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                    }

                    if expandedBooks.contains(bookName) {
                        chapterGrid(bookName: bookName, totalChapters: totalBookChapters, readSet: readSet)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Chapter Grid
    private func chapterGrid(bookName: String, totalChapters: Int, readSet: Set<Int>) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...totalChapters, id: \.self) { chapter in
                let isRead = readSet.contains(chapter)
                Button {
                    HapticManager.shared.impact(style: .light)
                    onNavigateToVerse?(bookName, chapter, 1)
                    dismiss()
                } label: {
                    Text("\(chapter)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isRead ? .black : .white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isRead ? Color.green : Color(.systemGray5))
                        )
                }
            }
        }
    }

    // MARK: - Mark Chapter as Read
    static func markChapterAsRead(bookName: String, chapterNumber: Int, context: ModelContext) {
        // Check if already marked
        let book = bookName
        let chapter = chapterNumber
        do {
            let descriptor = FetchDescriptor<ReadingProgress>(
                predicate: #Predicate { progress in
                    progress.bookName == book && progress.chapterNumber == chapter
                }
            )
            let existing = try context.fetch(descriptor)
            if existing.isEmpty {
                let progress = ReadingProgress(bookName: bookName, chapterNumber: chapterNumber)
                context.insert(progress)
                try context.save()
            }
        } catch {
            print("Failed to mark chapter as read: \(error.localizedDescription)")
        }
    }
}
