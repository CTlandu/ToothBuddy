import SwiftUI

// MARK: - 刷牙小贴士数据模型
struct BrushingTip: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let summary: String
    let content: String
}

// MARK: - 儿科牙医视角的趣味科普内容
private let brushingTips: [BrushingTip] = [
    BrushingTip(
        id: "why-2-min",
        emoji: "⏱️",
        title: "Why 2 Minutes?",
        summary: "The science behind the magic number.",
        content: """
        Ever wonder why dentists say "brush for 2 minutes"? Here's the secret: plaque—the sticky film on your teeth—needs time to break up. Rushing through means you might miss spots, especially in the back where cavities love to hide!

        Two minutes gives each tooth surface enough attention. Think of it like washing your hands: a quick rinse isn't enough, but 20 seconds does the job. Same idea—just longer because teeth have more nooks and crannies!

        Pro tip: Play a 2-minute song while brushing. When the song ends, you're done! 🎵
        """
    ),
    BrushingTip(
        id: "circle-vs-zigzag",
        emoji: "🔄",
        title: "Circle vs Zigzag",
        summary: "Gentle brushing techniques for little teeth.",
        content: """
        For kids, we recommend small circular motions—like drawing tiny circles on each tooth—instead of harsh back-and-forth scrubbing. Why? Gentle circles clean effectively without wearing down enamel or irritating gums.

        Imagine you're painting each tooth with a tiny, soft brush. Go tooth by tooth, front and back, top and bottom. Don't forget the chewing surfaces—those grooves are cavity hotspots!

        If your child finds circles tricky, a gentle zigzag along the gum line works too. The key is: soft bristles, light pressure, and covering every surface.
        """
    ),
    BrushingTip(
        id: "morning-night",
        emoji: "🌙",
        title: "Morning vs Night",
        summary: "Why both brushing times matter.",
        content: """
        Brushing twice a day isn't just a habit—it's strategic! Here's the deal:

        **Morning brush:** Overnight, bacteria multiply in your mouth. A morning brush clears them out and freshens your breath before the day starts.

        **Night brush:** This is the superstar! During the day, food and drinks leave sugars and acids on your teeth. If you skip the night brush, bacteria feast all night long—and that's when cavities form.

        Think of it like this: morning = fresh start, night = defense mode. Never skip the night brush—it's your teeth's best friend! 🦷
        """
    ),
    BrushingTip(
        id: "floss-fun",
        emoji: "🧵",
        title: "Fun with Floss",
        summary: "Making flossing fun for children.",
        content: """
        Flossing can feel boring to kids, but it's super important! The spaces between teeth are where 40% of plaque hides—and your toothbrush can't reach there.

        **Make it fun:**
        • Use flavored floss (watermelon, bubblegum—kids love it!)
        • Floss together—model the behavior and turn it into a game
        • Try floss picks if regular floss is tricky for small hands
        • Celebrate "floss wins" with a high-five or sticker

        Start flossing as soon as two teeth touch—usually around age 2–3. It's never too early to build the habit!
        """
    ),
    BrushingTip(
        id: "tongue-time",
        emoji: "👅",
        title: "Tongue Time!",
        summary: "Why we brush our tongue too.",
        content: """
        Your tongue is like a fuzzy carpet for bacteria! It has tiny bumps (papillae) where food particles and germs love to hide. That's why brushing your tongue matters—it fights bad breath and keeps your whole mouth healthier.

        **How to do it:** After brushing teeth, gently brush your tongue from back to front. No need to go too far back (that can trigger the gag reflex). A few swipes is enough!

        Some toothbrushes have a tongue scraper on the back—perfect for kids who are curious about trying it. Fresh breath = confident smiles! 😊
        """
    ),
    BrushingTip(
        id: "sugar-monster",
        emoji: "🍬",
        title: "The Sugar Monster",
        summary: "How sugar affects teeth (kid-friendly).",
        content: """
        Here's a fun fact: cavities don't come from sugar alone—they come from bacteria that LOVE sugar! When you eat sweets, these bacteria throw a party and make acid. That acid attacks your tooth enamel and creates holes (cavities).

        **The good news:** You don't have to give up treats! The trick is timing and brushing:
        • Eat sweets with meals (saliva helps wash them away)
        • Brush after sticky treats like gummies or caramel
        • Water is your teeth's best friend—rinse after snacks

        Think of brushing as your superhero power against the Sugar Monster. Brush well, and you win! 🦸
        """
    ),
    BrushingTip(
        id: "baby-teeth",
        emoji: "🦷",
        title: "Tooth Fairy's Secret",
        summary: "Why baby teeth matter.",
        content: """
        "They're going to fall out anyway—why bother?" Great question! Baby teeth are placeholders. They hold space for adult teeth and guide them into the right position. Lose a baby tooth too early to decay, and the adult tooth might come in crooked or crowded.

        Baby teeth also help with chewing, speaking clearly, and that adorable smile! Cavities in baby teeth can hurt, cause infections, and make eating uncomfortable.

        So treat baby teeth like the precious gems they are. The Tooth Fairy agrees—healthy teeth are worth celebrating! ✨
        """
    ),
    BrushingTip(
        id: "superhero-brushing",
        emoji: "🦸",
        title: "Superhero Brushing",
        summary: "Gamifying the routine.",
        content: """
        Turn brushing into an adventure! Kids love games, so why not make oral care one?

        **Ideas:**
        • "Defeat the plaque monsters"—each brush stroke is an attack
        • Timer challenge: "Can you brush until the song ends?"
        • Sticker chart: 2 brushes per day = 1 sticker, 7 days = small reward
        • Mirror check: "Did you get all the bad guys?" (show them the mirror)

        Consistency beats perfection. Even if the technique isn't perfect yet, making it fun means they'll actually do it—and that's half the battle!
        """
    )
]

// MARK: - Tips 主界面
struct TipsView: View {
    @State private var selectedTip: BrushingTip?
    @State private var contentAppeared = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(Array(brushingTips.enumerated()), id: \.element.id) { index, tip in
                    tipCard(tip, delay: Double(index) * 0.05)
                        .onTapGesture {
                            selectedTip = tip
                        }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .padding(.bottom, 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentAppeared = true
            }
        }
        .sheet(item: $selectedTip) { tip in
            TipDetailView(tip: tip)
        }
    }

    private func tipCard(_ tip: BrushingTip, delay: Double) -> some View {
        HStack(spacing: 14) {
            Text(tip.emoji)
                .font(.system(size: 36))
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(tip.summary)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMutedStrong)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.surfaceFrost)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.surfaceFrostBorder, lineWidth: 1)
                )
        )
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(delay), value: contentAppeared)
    }
}

// MARK: - Tip 详情弹窗
struct TipDetailView: View {
    let tip: BrushingTip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        Text(tip.emoji)
                            .font(.system(size: 48))
                            .frame(width: 72, height: 72)
                            .background(
                                LinearGradient(
                                    colors: [Theme.cardBlueStart.opacity(0.6), Theme.cardBlueEnd.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(tip.summary)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textMutedStrong)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.surfaceFrost)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Theme.surfaceFrostBorder, lineWidth: 1)
                            )
                    )

                    Group {
                        if let attributed = try? AttributedString(markdown: tip.content) {
                            Text(attributed)
                        } else {
                            Text(tip.content)
                        }
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background(Theme.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.accentBlue)
                }
            }
        }
    }
}

#Preview {
    TipsView()
        .background(Theme.appBackground.ignoresSafeArea())
}
