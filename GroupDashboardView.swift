import SwiftUI
import ToothBuddyCore

/// Everyone-sees-everyone Group dashboard (Spec 02 §6.5). No roles, no gating.
struct GroupDashboardView: View {
    @StateObject private var group = GroupStore.shared
    @StateObject private var profiles = ProfileStore.shared
    @StateObject private var store = BrushingStore.shared

    @State private var showCreate = false
    @State private var newGroupName = ""

    private var metrics: [DashboardMetric] {
        let all = store.allRecords()
        return profiles.profiles.map {
            DashboardMetrics.compute(profileID: $0.id, in: all, now: Date(),
                                     config: .default, calendar: .current)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                ForEach(profiles.profiles) { p in
                    if let m = metrics.first(where: { $0.profileID == p.id }) {
                        DashboardRow(profile: p, metric: m)
                    }
                }
                if profiles.profiles.isEmpty {
                    Text("No profiles yet.").foregroundColor(.secondary).padding(.top, 40)
                }
            }
            .padding(16)
        }
        .alert("Family group name", isPresented: $showCreate) {
            TextField("e.g. The Smiths", text: $newGroupName)
            Button("Create") { _ = group.createGroupWithAllProfiles(name: newGroupName) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Theme.accentBlue)
            if let name = group.groupName {
                Text(name).font(.system(size: 22, weight: .bold, design: .rounded))
                Button("Disband group", role: .destructive) { group.deleteGroup() }
                    .font(.system(size: 13))
            } else {
                Text("Family").font(.system(size: 22, weight: .bold, design: .rounded))
                Button {
                    newGroupName = ""
                    showCreate = true
                } label: {
                    Label("Create family group", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .disabled(profiles.profiles.isEmpty)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct DashboardRow: View {
    let profile: Profile
    let metric: DashboardMetric
    @ObservedObject private var care = CareStore.shared
    @ObservedObject private var store = BrushingStore.shared
    @State private var shareItem: SharePayload?

    private struct SharePayload: Identifiable { let id = UUID(); let url: URL }

    private func makeReport(days: Int) {
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -(days - 1), to: end) ?? end
        let data = ReportBuilder.build(profileID: profile.id, profileName: profile.name,
                                       in: store.allRecords(), start: start, end: end,
                                       now: end, config: .default, calendar: cal)
        if let url = ReportPDFRenderer.writeTempPDF(data) {
            shareItem = SharePayload(url: url)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: profile.symbol.systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(profile.colorTag.color)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name).font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 6) {
                        slotDot("sun.max.fill", metric.didMorningToday)
                        slotDot("moon.fill", metric.didEveningToday)
                        if metric.missedYesterday {
                            Text("missed yesterday")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Label("\(metric.currentStreak)", systemImage: "flame.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange)
                    Text("best \(metric.longestStreak)")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
                Menu {
                    Button("Last 30 days") { makeReport(days: 30) }
                    Button("Last 90 days") { makeReport(days: 90) }
                    Button("Last 365 days") { makeReport(days: 365) }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.accentBlue)
                        .frame(width: 34, height: 34)
                }
            }
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(metric.weeklyTrend.enumerated()), id: \.offset) { _, v in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.accentBlue.opacity(0.7))
                        .frame(height: CGFloat(max(2, v)) / 7.0 * 28 + 2)
                        .frame(maxWidth: .infinity)
                }
                Text("\(metric.last7DaysActive)/7")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 34)
            }
            .frame(height: 32)

            HStack(spacing: 8) {
                careChip(.brushHead, "Brush head", "🪥")
                careChip(.dentist, "Dentist", "🦷")
            }
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $shareItem) { payload in
            ShareSheet(items: [payload.url])
        }
    }

    private func slotDot(_ symbol: String, _ done: Bool) -> some View {
        Image(systemName: done ? symbol : "circle.dotted")
            .font(.system(size: 13))
            .foregroundColor(done ? Theme.accentBlue : .secondary)
    }

    @ViewBuilder
    private func careChip(_ kind: CareKind, _ label: String, _ icon: String) -> some View {
        let s = care.status(profile.id, kind)
        let (text, due): (String, Bool) = {
            guard let days = s.daysRemaining else { return ("set baseline", false) }
            if days < 0 { return ("overdue \(-days)d", true) }
            if s.isDue { return ("due today", true) }
            return ("in \(days)d", false)
        }()
        HStack(spacing: 5) {
            Text(icon).font(.system(size: 12))
            Text(label).font(.system(size: 11, weight: .semibold))
            Text(text).font(.system(size: 11)).foregroundColor(due ? .orange : .secondary)
            Button(s.daysRemaining == nil ? "Set" : "Done") {
                care.markDone(profile.id, kind)
                NotificationScheduler.shared.rescheduleCare(inputs: CareStore.shared.careInputs())
            }
            .font(.system(size: 11, weight: .bold))
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background((due ? Color.orange : Color.gray).opacity(0.12))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
}
