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
        .configurationDisplayName("Brushing Streak")
        .description("Your streak and whether today's brushing is done.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    private var hasData: Bool { snapshot.asOf != .distantPast }

    var body: some View {
        if !hasData {
            VStack(spacing: 6) {
                Image(systemName: "mouth.fill").font(.title2)
                Text("Open ToothBuddy to get started")
                    .font(.caption2).multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
        } else if family == .systemSmall {
            small
        } else {
            medium
        }
    }

    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text("\(snapshot.currentStreak)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
            }
            Text(snapshot.currentStreak == 1 ? "day streak" : "day streak")
                .font(.caption2).foregroundColor(.secondary)
        }
    }

    private func slot(_ label: String, _ done: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(done ? .green : .secondary)
            Text(label).font(.caption).foregroundColor(.secondary)
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
                    .font(.headline)
                streakBlock
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                slot("Morning", snapshot.amDone)
                slot("Evening", snapshot.pmDone)
                if snapshot.atRisk {
                    Text("Streak at risk tonight")
                        .font(.caption2).foregroundColor(.orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
