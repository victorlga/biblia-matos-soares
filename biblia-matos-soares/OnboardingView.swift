import SwiftUI
import SwiftData
import UIKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "hand.tap.fill",
            title: String(localized: "onboarding.feature1_title"),
            description: String(localized: "onboarding.feature1_desc"),
            demoContent: .verse
        ),
        OnboardingFeature(
            icon: "note.text",
            title: String(localized: "onboarding.feature2_title"),
            description: String(localized: "onboarding.feature2_desc"),
            demoContent: .none
        ),
        OnboardingFeature(
            icon: "bookmark.fill",
            title: String(localized: "onboarding.feature3_title"),
            description: String(localized: "onboarding.feature3_desc"),
            demoContent: .none
        ),
        OnboardingFeature(
            icon: "textformat.size",
            title: String(localized: "onboarding.feature4_title"),
            description: String(localized: "onboarding.feature4_desc"),
            demoContent: .none
        ),
        OnboardingFeature(
            icon: "magnifyingglass",
            title: String(localized: "onboarding.feature5_title"),
            description: String(localized: "onboarding.feature5_desc"),
            demoContent: .none
        )
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text(String(localized: "onboarding.welcome"))
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                    .padding(.bottom, 10)

                Text(String(localized: "onboarding.app_name"))
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)

                // Feature pages
                TabView(selection: $currentPage) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeatureCard(feature: feature)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<features.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button {
                            HapticManager.shared.impact(style: .light)
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            Text(String(localized: "common.previous"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                        }
                    }

                    Spacer()

                    Button {
                        HapticManager.shared.impact(style: .medium)
                        if currentPage < features.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            isPresented = false
                        }
                    } label: {
                        Text(currentPage < features.count - 1 ? String(localized: "common.next") : String(localized: "common.start"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingFeature {
    let icon: String
    let title: String
    let description: String
    let demoContent: DemoContent

    enum DemoContent {
        case verse
        case none
    }
}

struct FeatureCard: View {
    let feature: OnboardingFeature
    @State private var isHighlighted = false
    @State private var showNoteEditor = false

    // Stable demo verse that doesn't use SwiftData persistence
    private let demoVerseData = (
        bookName: "Gênesis",
        chapterNumber: 1,
        verseNumber: 1,
        text: "No princípio criou Deus o céu e a terra."
    )

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: feature.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)

            // Title
            Text(feature.title)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(.white)

            // Demo verse for first feature
            if feature.demoContent == .verse {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("1")
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundColor(.secondary)

                        Text("No princípio criou Deus o céu e a terra.")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .padding(.vertical, isHighlighted ? 4 : 0)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isHighlighted ? Color.yellow.opacity(0.3) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    )
                    .contextMenu {
                        Button {
                            HapticManager.shared.impact(style: .medium)
                            withAnimation {
                                isHighlighted.toggle()
                            }
                        } label: {
                            Label(isHighlighted ? String(localized: "context.remove_highlight") : String(localized: "context.highlight"), systemImage: isHighlighted ? "bookmark.slash" : "bookmark")
                        }
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showNoteEditor = true
                        } label: {
                            Label(String(localized: "context.add_note"), systemImage: "note.text")
                        }
                        Button {
                            HapticManager.shared.impact(style: .light)
                            shareVerse()
                        } label: {
                            Label(String(localized: "common.share"), systemImage: "square.and.arrow.up")
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        HapticManager.shared.impact(style: .medium)
                        withAnimation {
                            isHighlighted.toggle()
                        }
                    }

                    // Tap indicator
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                        Text(String(localized: "onboarding.tap_hint"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    .padding(.leading, 10)
                }
                .padding(.horizontal, 30)
            }

            // Description
            Text(feature.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .padding(.top, feature.demoContent == .verse ? 10 : 0)

            Spacer()
        }
        .padding(.top, 20)
        .sheet(isPresented: $showNoteEditor) {
            DemoNoteEditorWrapper(
                bookName: demoVerseData.bookName,
                chapterNumber: demoVerseData.chapterNumber,
                verseNumber: demoVerseData.verseNumber,
                text: demoVerseData.text
            )
        }
    }

    private func shareVerse() {
        let shareText = "Gênesis 1:1 - No princípio criou Deus o céu e a terra."
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the top-most presented view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(activityVC, animated: true)
        }
    }
}

// Wrapper that creates a fresh container and verse for the demo note editor
struct DemoNoteEditorWrapper: View {
    let bookName: String
    let chapterNumber: Int
    let verseNumber: Int
    let text: String

    @State private var demoVerse: BibleVerse?

    // Create a fresh container each time this view appears
    private let demoContainer: ModelContainer = {
        let schema = Schema([BibleVerse.self, VerseNote.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create demo ModelContainer: \(error)")
        }
    }()

    var body: some View {
        Group {
            if let verse = demoVerse {
                NoteEditorView(verse: verse)
                    .modelContainer(demoContainer)
            } else {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            createDemoVerse()
        }
    }

    private func createDemoVerse() {
        let verse = BibleVerse(
            bookName: bookName,
            chapterNumber: chapterNumber,
            verseNumber: verseNumber,
            text: text
        )
        demoContainer.mainContext.insert(verse)
        try? demoContainer.mainContext.save()
        demoVerse = verse
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
