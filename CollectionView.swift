import SwiftUI
import ToothBuddyCore

/// U11 — the collectible "book": browse the friends Buddy has found. Owned items show full;
/// locked ones are silhouettes. Purely additive progression — no loser state, no spend UI (v1).
struct CollectionView: View {
    @ObservedObject var retention: RetentionStore
    let onDismiss: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Buddy's Friends")
                        .font(Duo.Fnt.ebd(22))
                        .foregroundColor(Duo.ink)
                    let p = retention.collectionProgress
                    Text("\(p.owned) / \(p.total) found")
                        .font(Duo.Fnt.sbd(13))
                        .foregroundColor(Duo.muted)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Duo.muted)
                }
            }
            .padding(20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Collectible.all) { c in
                        cell(c, owned: retention.ownedCollectibleIds.contains(c.id))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Duo.pageBackground.ignoresSafeArea())
    }

    private func cell(_ c: Collectible, owned: Bool) -> some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(owned ? Duo.foamFill : Duo.stoneLight)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Duo.ink, lineWidth: 2)
                Image(systemName: owned ? icon(c.rarity) : "questionmark")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(owned ? color(c.rarity) : Duo.muted.opacity(0.6))
            }
            .frame(height: 88)
            Text(owned ? c.name : "???")
                .font(Duo.Fnt.ebd(12))
                .foregroundColor(owned ? Duo.ink : Duo.muted)
                .lineLimit(1)
        }
    }

    private func color(_ r: Rarity) -> Color {
        switch r {
        case .common:    return Duo.blue
        case .rare:      return Duo.green
        case .legendary: return Duo.yellow
        }
    }

    private func icon(_ r: Rarity) -> String {
        switch r {
        case .common:    return "circle.fill"
        case .rare:      return "star.fill"
        case .legendary: return "crown.fill"
        }
    }
}
