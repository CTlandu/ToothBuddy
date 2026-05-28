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
        .configurationDisplayName(Text("Brushing Streak"))
        .description(Text("Your streak and whether today's brushing is done."))
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

    /// Chunky streak block — yellow flame badge + big rounded digit.
    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                ZStack {
                    Capsule().fill(Duo.yellowShadow).offset(y: 2)
                    HStack(spacing: 3) {
                        Text("🔥").font(.system(size: 14))
                        Text("\(snapshot.currentStreak)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(Duo.ink)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Duo.yellow))
                    .overlay(Capsule().stroke(Duo.ink, lineWidth: 1.5))
                }
                .fixedSize()
            }
            Text("day streak")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundColor(Duo.muted)
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
        VStack(alignment: .leading, spacing: 8) {
            streakBlock
            Spacer(minLength: 0)
            slot("Morning", snapshot.amDone)
            slot("Evening", snapshot.pmDone)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.profileName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Duo.ink)
                streakBlock
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                slot("Morning", snapshot.amDone)
                slot("Evening", snapshot.pmDone)
                if snapshot.atRisk {
                    Text("Streak at risk tonight")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Duo.red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
