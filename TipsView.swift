import SwiftUI
import ToothBuddyCore

// MARK: - Category system

enum TipCategory: String {
    case technique = "Technique"
    case habit     = "Habit"
    case science   = "Science"
    case nutrition = "Nutrition"
    case funFact   = "Fun Fact"

    var accentColor: Color {
        switch self {
        case .technique: return Color(red: 59/255,  green: 130/255, blue: 246/255) // sky blue
        case .habit:     return Color(red: 249/255, green: 115/255, blue: 22/255)  // orange
        case .science:   return Color(red: 16/255,  green: 185/255, blue: 129/255) // teal
        case .nutrition: return Color(red: 139/255, green: 92/255,  blue: 246/255) // purple
        case .funFact:   return Color(red: 245/255, green: 158/255, blue: 11/255)  // amber
        }
    }

    var cardBackground: Color { accentColor.opacity(0.10) }
    var tagBackground:  Color { accentColor.opacity(0.15) }
}

// MARK: - Data model

struct BrushingTip: Identifiable {
    let id: String
    let systemImage: String
    let title: String
    let summary: String
    /// Markdown content. Paragraphs separated by blank lines.
    /// Lines starting with • are rendered as coloured bullets.
    /// Paragraphs containing 💡 are rendered as callout boxes.
    let content: String
    let category: TipCategory
    let readTime: Int
}

// MARK: - Content data

private let brushingTips: [BrushingTip] = [
    BrushingTip(
        id: "why-2-min",
        systemImage: "timer",
        title: "Why 2 Minutes?",
        summary: "The science behind the magic number.",
        content: """
        Ever wonder why dentists say "brush for 2 minutes"? Here's the secret: plaque — the sticky film on your teeth — needs time to break up. Rushing through means you miss spots, especially in the back where cavities love to hide!

        Two minutes gives each tooth surface enough attention. Think of it like washing your hands: a quick rinse isn't enough, but 20 seconds does the job. Same idea — just longer, because teeth have more nooks and crannies.

        **💡 Pro tip:** Play a 2-minute song while brushing. When the song ends, you're done! 🎵
        """,
        category: .science,
        readTime: 1
    ),
    BrushingTip(
        id: "circle-vs-zigzag",
        systemImage: "arrow.2.circlepath",
        title: "Circle vs Zigzag",
        summary: "Gentle brushing techniques for little teeth.",
        content: """
        For kids, we recommend **small circular motions** — like drawing tiny circles on each tooth — instead of harsh back-and-forth scrubbing. Gentle circles clean effectively without wearing down enamel or irritating gums.

        Imagine you're painting each tooth with a tiny, soft brush. Go tooth by tooth, front and back, top and bottom. Don't forget the chewing surfaces — those grooves are cavity hotspots!

        If your child finds circles tricky, a gentle zigzag along the gum line works too. The key: **soft bristles, light pressure, and full coverage**.
        """,
        category: .technique,
        readTime: 1
    ),
    BrushingTip(
        id: "morning-night",
        systemImage: "moon.fill",
        title: "Morning vs Night",
        summary: "Why both brushing times matter.",
        content: """
        Brushing twice a day isn't just habit — it's strategic!

        **🌅 Morning brush:** Overnight, bacteria multiply in your mouth. A morning brush clears them out and freshens your breath before the day starts.

        **🌙 Night brush:** This is the superstar! During the day, food and drinks leave sugars and acids on your teeth. If you skip the night brush, bacteria feast all night — and that's when cavities form.

        **Never skip the night brush.** Morning = fresh start. Night = defense mode. Your teeth will thank you! 🦷
        """,
        category: .habit,
        readTime: 1
    ),
    BrushingTip(
        id: "floss-fun",
        systemImage: "link.circle.fill",
        title: "Fun with Floss",
        summary: "Making flossing fun for children.",
        content: """
        Flossing can feel boring to kids, but it's super important! The spaces between teeth are where **40% of plaque hides** — and your toothbrush can't reach there.

        **Make it fun:**
        • Use flavored floss (watermelon, bubblegum — kids love it!)
        • Floss together — model the behavior and turn it into a game
        • Try floss picks if regular floss is tricky for small hands
        • Celebrate "floss wins" with a high-five or sticker

        Start flossing as soon as two teeth touch — usually around **age 2–3**. It's never too early to build the habit!
        """,
        category: .technique,
        readTime: 1
    ),
    BrushingTip(
        id: "tongue-time",
        systemImage: "mouth.fill",
        title: "Tongue Time!",
        summary: "Why we brush our tongue too.",
        content: """
        Your tongue is like a fuzzy carpet for bacteria! It has tiny bumps (papillae) where food particles and germs love to hide. Brushing it fights bad breath and keeps your whole mouth healthier.

        **How to do it:** After brushing teeth, gently brush your tongue from back to front. No need to go too far back (it can trigger the gag reflex). A few swipes is enough!

        Some toothbrushes have a tongue scraper on the back — perfect for curious kids. **Fresh breath = confident smiles!** 😊
        """,
        category: .technique,
        readTime: 1
    ),
    BrushingTip(
        id: "sugar-monster",
        systemImage: "xmark.circle.fill",
        title: "The Sugar Monster",
        summary: "How sugar affects teeth — kid-friendly!",
        content: """
        Cavities don't come from sugar alone — they come from **bacteria that love sugar**! When you eat sweets, these bacteria throw a party and make acid. That acid attacks your tooth enamel and creates holes (cavities).

        **The good news:** You don't have to give up treats! The trick is timing and brushing:
        • Eat sweets with meals — saliva helps wash them away
        • Brush after sticky treats like gummies or caramel
        • Water is your teeth's best friend — rinse after snacks

        Think of brushing as your **superhero power** against the Sugar Monster. Brush well, and you win! 🦸
        """,
        category: .nutrition,
        readTime: 1
    ),
    BrushingTip(
        id: "baby-teeth",
        systemImage: "mouth.fill",
        title: "Tooth Fairy's Secret",
        summary: "Why baby teeth matter more than you think.",
        content: """
        "They're going to fall out anyway — why bother?" Great question! **Baby teeth are placeholders.** They hold space for adult teeth and guide them into the right position. Lose one too early to decay, and the adult tooth might come in crooked or crowded.

        Baby teeth also help with chewing, speaking clearly, and that adorable smile! Cavities in baby teeth can hurt, cause infections, and make eating uncomfortable.

        So treat baby teeth like the precious gems they are. The Tooth Fairy agrees — **healthy teeth are worth celebrating!** ✨
        """,
        category: .funFact,
        readTime: 1
    ),
    BrushingTip(
        id: "superhero-brushing",
        systemImage: "bolt.circle.fill",
        title: "Superhero Brushing",
        summary: "Gamifying the brushing routine.",
        content: """
        Turn brushing into an adventure! Kids love games, so why not make oral care one?

        **Ideas to try:**
        • "Defeat the plaque monsters" — each brush stroke is an attack!
        • Timer challenge: "Can you brush until the song ends?"
        • Sticker chart: 2 brushes per day = 1 sticker, 7 days = small reward
        • Mirror check: "Did you get all the bad guys?" (show them the mirror!)

        **Consistency beats perfection.** Even if the technique isn't perfect yet, making it fun means they'll actually do it — and that's half the battle!
        """,
        category: .habit,
        readTime: 1
    ),
]

// MARK: - Shared icon view helper

/// Renders a tip icon as an SF Symbol.
@ViewBuilder
private func tipEmojiView(_ systemImage: String, size: CGFloat, accent: Color = Duo.green) -> some View {
    Image(systemName: systemImage)
        .font(.system(size: size, weight: .semibold))
        .foregroundColor(accent)
        .symbolRenderingMode(.hierarchical)
}

// MARK: - Tips main view

struct TipsView: View {
    @State private var selectedTip: BrushingTip?
    @State private var contentAppeared = false
    @StateObject private var store = BrushingStore.shared
    @State private var selectedLesson: Lesson?

    /// Distinct active days for the active profile (drives course unlocks, Spec 03 §5.4).
    private var activeDays: Int {
        let cal = Calendar.current
        return Set(store.records.map { cal.startOfDay(for: $0.startDate) }).count
    }
    private var unlockedLessons: Int {
        CourseProgression.unlockedCount(activeDays: activeDays,
                                        totalLessons: CourseLibrary.all.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                courseSection
                    .padding(.horizontal, 18)

                Text("BRUSHING TIPS")
                    .font(Duo.Fnt.ebd(12))
                    .tracking(1.5)
                    .foregroundColor(Duo.muted)
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                // Hero card — first tip
                if let hero = brushingTips.first {
                    heroCard(hero)
                        .padding(.horizontal, 18)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 18)
                        .animation(.easeOut(duration: 0.45), value: contentAppeared)
                }

                // Regular cards — remaining tips
                LazyVStack(spacing: 10) {
                    ForEach(Array(brushingTips.dropFirst().enumerated()), id: \.element.id) { index, tip in
                        tipCard(tip)
                            .padding(.horizontal, 18)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 12)
                            .animation(.easeOut(duration: 0.4).delay(Double(index + 1) * 0.06), value: contentAppeared)
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { contentAppeared = true }
        }
        .sheet(item: $selectedTip) { tip in
            TipDetailView(tip: tip)
        }
        .sheet(item: $selectedLesson) { lesson in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(lesson.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text(lesson.body)
                            .font(.system(size: 16))
                            .foregroundColor(Duo.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
                .navigationTitle("Lesson \(lesson.id)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: Oral-health course (Spec 03 §5.4)

    private var courseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ORAL-HEALTH COURSE")
                .font(Duo.Fnt.ebd(12))
                .tracking(1.5)
                .foregroundColor(Duo.muted)
            Text("\(unlockedLessons) of \(CourseLibrary.all.count) lessons unlocked — keep brushing to unlock more")
                .font(Duo.Fnt.sbd(12))
                .foregroundColor(Duo.muted)
            ForEach(CourseLibrary.all) { lesson in
                courseRow(lesson, locked: lesson.id > unlockedLessons)
            }
        }
    }

    private func courseRow(_ lesson: Lesson, locked: Bool) -> some View {
        Button { if !locked { selectedLesson = lesson } } label: {
            DuoCard(face: locked ? Duo.stoneLight.opacity(0.5) : .white, padding: 12) {
                HStack(spacing: 12) {
                    Image(systemName: locked ? "lock.fill" : "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(locked ? Duo.muted : Duo.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title)
                            .font(Duo.Fnt.ebd(15))
                            .foregroundColor(locked ? Duo.muted : Duo.ink)
                        if locked {
                            Text("Unlocks after \((lesson.id - 1) * CourseProgression.lessonEvery) active days")
                                .font(Duo.Fnt.sbd(11))
                                .foregroundColor(Duo.muted)
                        }
                    }
                    Spacer()
                    if !locked {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Duo.muted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }

    // MARK: Hero card

    private func heroCard(_ tip: BrushingTip) -> some View {
        Button { selectedTip = tip } label: {
            DuoCard(face: tip.category.cardBackground, padding: 22) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        categoryTag(tip.category)
                        Spacer()
                        Label("\(tip.readTime) min read", systemImage: "clock")
                            .font(Duo.Fnt.ebd(11))
                            .foregroundColor(tip.category.accentColor)
                    }

                    tipEmojiView(tip.systemImage, size: 72, accent: tip.category.accentColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 14)

                    Text(tip.title)
                        .font(Duo.Fnt.ebd(24))
                        .foregroundColor(Duo.ink)
                        .padding(.bottom, 6)

                    Text(tip.summary)
                        .font(Duo.Fnt.sbd(14))
                        .foregroundColor(Duo.muted)
                        .lineLimit(2)
                        .padding(.bottom, 16)

                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Read more")
                                .font(Duo.Fnt.ebd(13))
                                .tracking(0.3)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(tip.category.accentColor)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Regular card

    private func tipCard(_ tip: BrushingTip) -> some View {
        Button { selectedTip = tip } label: {
            DuoCard(face: .white, padding: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Duo.ink).offset(y: 2)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tip.category.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Duo.ink, lineWidth: 2))
                        tipEmojiView(tip.systemImage, size: 26, accent: tip.category.accentColor)
                    }
                    .frame(width: 52, height: 54)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            categoryTag(tip.category)
                            Spacer()
                            Text("\(tip.readTime) min")
                                .font(Duo.Fnt.sbd(11))
                                .foregroundColor(Duo.muted)
                        }
                        Text(tip.title)
                            .font(Duo.Fnt.ebd(15))
                            .foregroundColor(Duo.ink)
                        Text(tip.summary)
                            .font(Duo.Fnt.sbd(12))
                            .foregroundColor(Duo.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tip.category.accentColor.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func categoryTag(_ category: TipCategory) -> some View {
        Text(category.rawValue)
            .font(Duo.Fnt.ebd(10))
            .tracking(0.6)
            .foregroundColor(category.accentColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(category.tagBackground))
            .overlay(Capsule().stroke(category.accentColor.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Tip detail view

struct TipDetailView: View {
    let tip: BrushingTip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero header
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 16) {
                            tipEmojiView(tip.systemImage, size: 52, accent: tip.category.accentColor)
                                .frame(width: 78, height: 78)
                                .background(tip.category.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            VStack(alignment: .leading, spacing: 8) {
                                categoryTag(tip.category)
                                Text(tip.title)
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundColor(Duo.ink)
                            }
                            Spacer()
                        }

                        Text(tip.summary)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Duo.muted)
                            .italic()

                        Rectangle()
                            .fill(tip.category.accentColor.opacity(0.25))
                            .frame(height: 1.5)
                            .clipShape(Capsule())
                    }
                    .padding(24)

                    // Article body
                    contentView
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }
            .background(Duo.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tip.category.accentColor)
                }
            }
        }
    }

    // MARK: Content renderer

    private var contentView: some View {
        let paragraphs = tip.content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                paragraphView(paragraph)
            }
        }
    }

    @ViewBuilder
    private func paragraphView(_ text: String) -> some View {
        if text.contains("💡") || text.lowercased().contains("pro tip") {
            calloutView(text)
        } else if text.contains("•") {
            bulletBlockView(text)
        } else {
            Group {
                if let attributed = try? AttributedString(markdown: text) {
                    Text(attributed)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Duo.ink)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundColor(Duo.ink)
                        .lineSpacing(6)
                }
            }
        }
    }

    /// Renders a block that may contain a header line + bullet items.
    @ViewBuilder
    private func bulletBlockView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("•") {
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(tip.category.accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        Group {
                            if let attr = try? AttributedString(markdown: String(trimmed.dropFirst().trimmingCharacters(in: .whitespaces))) {
                                Text(attr)
                            } else {
                                Text(trimmed.dropFirst().trimmingCharacters(in: .whitespaces))
                            }
                        }
                        .font(.system(size: 16))
                        .foregroundColor(Duo.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                } else if !trimmed.isEmpty {
                    Group {
                        if let attr = try? AttributedString(markdown: trimmed) {
                            Text(attr)
                        } else {
                            Text(trimmed)
                        }
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Duo.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Renders a 💡 pro-tip callout box.
    @ViewBuilder
    private func calloutView(_ text: String) -> some View {
        let cleaned = text
            .replacingOccurrences(of: "**💡 Pro tip:** ", with: "")
            .replacingOccurrences(of: "**💡 Pro tip:**", with: "")
            .replacingOccurrences(of: "💡 ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundColor(tip.category.accentColor)
                .padding(.top, 2)
            Group {
                if let attr = try? AttributedString(markdown: cleaned) {
                    Text(attr)
                } else {
                    Text(cleaned)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Duo.ink)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(tip.category.tagBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(tip.category.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func categoryTag(_ category: TipCategory) -> some View {
        Text(category.rawValue)
            .font(.system(size: 10, weight: .heavy))
            .tracking(0.5)
            .foregroundColor(category.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(category.tagBackground))
    }
}

#Preview {
    TipsView()
        .background(Duo.pageBackground.ignoresSafeArea())
}
