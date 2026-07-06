//
//  ProductiveFeedView.swift
//  Wellness App
//
//  A productive alternative to doomscrolling: a swipeable reel of short
//  educational cards, bite-size lessons by topic, and links to free public
//  domain books. Built to give the pull of a feed without the junk.
//

import SwiftUI

// MARK: - Content models

struct LearnCard: Identifiable {
    let id = UUID()
    let topic: String
    let title: String
    let body: String
}

struct Lesson: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct LearnTopic: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    let lessons: [Lesson]
}

struct FreeBook: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let url: URL
}

enum ProductiveContent {
    static let reel: [LearnCard] = [
        .init(topic: "Sleep", title: "Your brain cleans itself at night", body: "During deep sleep the brain's glymphatic system flushes out waste proteins that build up while you're awake. Skimp on sleep and that cleanup gets cut short."),
        .init(topic: "Nutrition", title: "Protein keeps you full", body: "Gram for gram, protein is the most satiating macronutrient. A higher-protein breakfast can blunt cravings for the rest of the day."),
        .init(topic: "Fitness", title: "Muscle burns calories at rest", body: "Muscle tissue is metabolically active, so strength training raises the calories you burn even on days you don't work out."),
        .init(topic: "Mind", title: "Attention is a muscle", body: "Focus improves with practice. Even a few minutes of single-tasking, without switching apps, strengthens your ability to concentrate."),
        .init(topic: "Science", title: "You share genes with a banana", body: "Humans and bananas share roughly 60% of their genes, a reminder of how much basic biology life on Earth has in common."),
        .init(topic: "Psychology", title: "The two-minute rule", body: "If a task takes less than two minutes, do it now. It stops small tasks from piling into overwhelming mental clutter."),
        .init(topic: "Sleep", title: "Light sets your body clock", body: "Morning sunlight anchors your circadian rhythm and helps you feel sleepy at the right time that night. Ten minutes outside early goes a long way."),
        .init(topic: "Nutrition", title: "Fibre feeds your gut", body: "The bacteria in your gut ferment fibre into compounds that lower inflammation. Most people eat about half the fibre they need."),
        .init(topic: "History", title: "The pyramid builders were paid", body: "Evidence shows Egypt's pyramids were built by paid, well-fed laborers, not slaves, who left behind graffiti proudly naming their work crews."),
        .init(topic: "Mind", title: "Naming a feeling calms it", body: "Labeling an emotion ('I feel anxious') reduces activity in the brain's alarm center. Putting feelings into words genuinely takes the edge off."),
        .init(topic: "Fitness", title: "Walking counts", body: "You don't need a gym to benefit. A brisk daily walk improves heart health, mood, and blood sugar, and it's the most sustainable habit for most people."),
        .init(topic: "Science", title: "Honey never spoils", body: "Archaeologists have found 3,000-year-old honey still edible. Its low moisture and acidity make it nearly impossible for bacteria to grow."),
        .init(topic: "Productivity", title: "Single-task to go faster", body: "Task-switching has a hidden cost: each switch leaves 'attention residue'. Doing one thing at a time is usually the faster route."),
        .init(topic: "Mind", title: "Breathing out longer relaxes you", body: "A longer exhale than inhale nudges your nervous system toward calm. Try inhaling for four counts and exhaling for six."),
        .init(topic: "Nutrition", title: "Hydration affects focus", body: "Even mild dehydration can dent concentration and mood. If you feel foggy in the afternoon, water is worth trying before more coffee."),
        .init(topic: "Psychology", title: "Small wins compound", body: "Progress, however tiny, is one of the strongest motivators. Tracking a small daily habit builds momentum that willpower alone can't."),
        .init(topic: "Science", title: "Your body glows (faintly)", body: "Humans emit a small amount of visible light through metabolic reactions, far too dim for the eye to see but real and measurable."),
        .init(topic: "Fitness", title: "Recovery is where you grow", body: "Training breaks muscle down; rest and protein build it back stronger. More is not always better, and sleep is part of the workout."),
    ]

    static let topics: [LearnTopic] = [
        .init(name: "Better sleep", systemImage: "moon.stars.fill", lessons: [
            .init(title: "Keep a consistent schedule", body: "Going to bed and waking at similar times, even on weekends, stabilizes your body clock and makes falling asleep easier."),
            .init(title: "Wind down without screens", body: "Bright screens late at night suppress melatonin. Dim the lights and step away from your phone 30–60 minutes before bed."),
            .init(title: "Cool, dark, quiet", body: "A slightly cool room (around 18°C), darkness, and quiet are the three biggest environmental levers for deep sleep."),
        ]),
        .init(name: "Eating well", systemImage: "leaf.fill", lessons: [
            .init(title: "Build a balanced plate", body: "Aim for half vegetables, a quarter protein, and a quarter whole grains. It's simple and works without counting anything."),
            .init(title: "Protein at every meal", body: "Spreading protein across meals supports muscle and keeps you full. Eggs, yogurt, beans, tofu, fish, and lean meat all count."),
            .init(title: "Watch liquid calories", body: "Sugary drinks add calories without filling you up. Water, sparkling water, and unsweetened tea are easy swaps."),
        ]),
        .init(name: "Focus & habits", systemImage: "brain.head.profile", lessons: [
            .init(title: "Make the habit obvious", body: "Put a cue in your path: gym clothes by the bed, a water bottle on your desk. Environment beats motivation."),
            .init(title: "Shrink it to start", body: "Commit to two minutes. 'Read one page' or 'do one push-up' removes the friction that stops you starting."),
            .init(title: "Protect deep work", body: "Batch distractions. Turn off notifications for a set block and let your mind sink into one task."),
        ]),
        .init(name: "Managing stress", systemImage: "heart.fill", lessons: [
            .init(title: "Name it to tame it", body: "Labeling what you feel reduces its intensity. A quick 'I'm feeling overwhelmed' creates useful distance."),
            .init(title: "Move your body", body: "A short walk or stretch discharges stress hormones and resets your state faster than willpower."),
            .init(title: "Box breathing", body: "Inhale 4, hold 4, exhale 4, hold 4. A few rounds signals safety to your nervous system."),
        ]),
    ]

    static let books: [FreeBook] = [
        .init(title: "Meditations", author: "Marcus Aurelius", url: URL(string: "https://www.gutenberg.org/ebooks/2680")!),
        .init(title: "The Art of War", author: "Sun Tzu", url: URL(string: "https://www.gutenberg.org/ebooks/132")!),
        .init(title: "Walden", author: "Henry David Thoreau", url: URL(string: "https://www.gutenberg.org/ebooks/205")!),
        .init(title: "The Prince", author: "Niccolò Machiavelli", url: URL(string: "https://www.gutenberg.org/ebooks/1232")!),
        .init(title: "Pride and Prejudice", author: "Jane Austen", url: URL(string: "https://www.gutenberg.org/ebooks/1342")!),
        .init(title: "The Autobiography of Benjamin Franklin", author: "Benjamin Franklin", url: URL(string: "https://www.gutenberg.org/ebooks/20203")!),
        .init(title: "Frankenstein", author: "Mary Shelley", url: URL(string: "https://www.gutenberg.org/ebooks/84")!),
        .init(title: "The Wealth of Nations", author: "Adam Smith", url: URL(string: "https://www.gutenberg.org/ebooks/3300")!),
    ]
}

// MARK: - View

struct ProductiveFeedView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case reel, lessons, books
        var id: String { rawValue }
        var label: String {
            switch self {
            case .reel:    "Reel"
            case .lessons: "Lessons"
            case .books:   "Books"
            }
        }
    }

    @State private var mode: Mode = .reel

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch mode {
            case .reel:    reel
            case .lessons: lessons
            case .books:   books
            }
        }
        .navigationTitle("Productive feed")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: Reel

    private var reel: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(ProductiveContent.reel) { card in
                    reelCard(card)
                        .containerRelativeFrame(.vertical)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }

    private func reelCard(_ card: LearnCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 0)
            Text(card.topic.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.restore)
            Text(card.title)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(card.body)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Label("Swipe up for more", systemImage: "chevron.up")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.topic). \(card.title). \(card.body)")
    }

    // MARK: Lessons

    private var lessons: some View {
        List {
            ForEach(ProductiveContent.topics) { topic in
                Section {
                    ForEach(topic.lessons) { lesson in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title).font(.subheadline.weight(.semibold))
                            Text(lesson.body).font(.footnote).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Label(topic.name, systemImage: topic.systemImage)
                }
            }
        }
    }

    // MARK: Books

    private var books: some View {
        List {
            Section {
                ForEach(ProductiveContent.books) { book in
                    Link(destination: book.url) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title).foregroundStyle(.primary)
                                Text(book.author).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(Theme.restore)
                        }
                    }
                }
            } footer: {
                Text("Free public domain books from Project Gutenberg. Opens in your browser.")
            }
        }
    }
}

#Preview {
    NavigationStack { ProductiveFeedView() }
}
