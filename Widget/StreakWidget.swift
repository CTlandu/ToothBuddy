import WidgetKit
import SwiftUI
import ToothBuddyCore

/// Home Screen widget (small + medium) for the active profile (Spec 05 §6.4). Reads
/// only the App Group snapshot — never Core Data. Never blank: a friendly placeholder
/// stands in until the app has written data.
struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), snapshot: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: Date(), snapshot: AppGroup.readSnapshot()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: Date(), snapshot: AppGroup.readSnapshot())
        // The app reloads timelines on every relevant change; this is just a safety net.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ToothBuddyStreak", provider: StreakProvider()) { entry in
            StreakWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName(Text("Brushing"))
        .description(Text("Today's brushing quality, plus your streak."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    private var hasData: Bool { snapshot.asOf != .distantPast }

    var body: some View {
        if !hasData {
            VStack(spacing: 8) {
                Image(systemName: "mouth.fill")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(Duo.green)
                Text("Open ToothBuddy to get started")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Duo.muted)
            }
            .padding()
        } else if family == .systemSmall {
            small
        } else {
            medium
        }
    }

    /// U12 hero — today's brushing quality.
    private var qualityBlock: some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.todayThoroughCount > 0 ? "checkmark.seal.fill" : "mouth.fill")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(snapshot.todayThoroughCount > 0 ? Duo.green : Duo.muted)
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.todayThoroughCount > 0 ? "Brushed well" : "Brush today")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Duo.ink)
                Text("\(snapshot.todayThoroughCount) thorough today")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(Duo.muted)
            }
        }
    }

    /// Demoted streak — a small flame badge, no longer the hero.
    private var streakBadge: some View {
        HStack(spacing: 3) {
            Text("🔥").font(.system(size: 11))
            Text("\(snapshot.currentStreak)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Duo.ink)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(Capsule().fill(Duo.yellow))
        .overlay(Capsule().stroke(Duo.ink, lineWidth: 1.5))
    }

    /// Last session's coverage + verification.
    private var lastCoverage: some View {
        HStack(spacing: 5) {
            Image(systemName: snapshot.lastVerified ? "checkmark.shield.fill" : "hand.draw.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(snapshot.lastVerified ? Duo.green : Duo.muted)
            Text("\(snapshot.lastZonesMet)/6 areas")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Duo.ink)
        }
    }

    private func slot(_ label: LocalizedStringKey, _ done: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(done ? Duo.green : Duo.muted)
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Duo.ink)
                // LocalizedStringKey routes through Localizable.xcstrings.
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            qualityBlock
            Spacer(minLength: 0)
            slot("Morning", snapshot.amDone)
            slot("Evening", snapshot.pmDone)
            HStack { Spacer(); streakBadge }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.profileName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Duo.ink)
                qualityBlock
                lastCoverage
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                streakBadge
                slot("Morning", snapshot.amDone)
                slot("Evening", snapshot.pmDone)
                if snapshot.atRisk {
                    Text("Brush before bed")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Duo.red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
