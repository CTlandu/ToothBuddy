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
                    VStack(spacing: 14) {
                        BuddyView()
                            .frame(width: 96, height: 110)
                            .opacity(0.55)
                        Text("No profiles yet")
                            .font(Duo.Fnt.ebd(18))
                            .foregroundColor(Duo.ink)
                        Text("Add a profile to start tracking the family.")
                            .font(Duo.Fnt.sbd(13))
                            .foregroundColor(Duo.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
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
        VStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(Duo.green)
            if let name = group.groupName {
                Text(name)
                    .font(Duo.Fnt.ebd(24))
                    .foregroundColor(Duo.ink)
                Button("Disband group", role: .destructive) { group.deleteGroup() }
                    .font(Duo.Fnt.sbd(12))
                    .foregroundColor(Duo.red)
            } else {
                Text("Family")
                    .font(Duo.Fnt.ebd(24))
                    .foregroundColor(Duo.ink)
                if !profiles.profiles.isEmpty {
                    Button {
                        newGroupName = ""
                        showCreate = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Create family group")
                                .font(Duo.Fnt.ebd(13))
                                .tracking(0.4)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(DuoButtonStyle(role: .primary))
                    .fixedSize()
                }
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
        DuoCard(face: .white, padding: 14) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Duo.ink).offset(y: 2)
                        Image(systemName: profile.symbol.systemImage)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(profile.colorTag.color))
                            .overlay(Circle().stroke(Duo.ink, lineWidth: 2))
                    }
                    .frame(width: 42, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.name)
                            .font(Duo.Fnt.ebd(17))
                            .foregroundColor(Duo.ink)
                        HStack(spacing: 6) {
                            slotDot("sun.max.fill", metric.didMorningToday)
                            slotDot("moon.fill", metric.didEveningToday)
                            if metric.missedYesterday {
                                Text("missed yesterday")
                                    .font(Duo.Fnt.sbd(10))
                                    .foregroundColor(Duo.red)
                            }
                        }
                    }
                    Spacer()
                    DuoBadge(text: "\(metric.currentStreak)",
                             leadingEmoji: "🔥",
                             role: .warning)
                    Menu {
                        Button("Last 30 days") { makeReport(days: 30) }
                        Button("Last 90 days") { makeReport(days: 90) }
                        Button("Last 365 days") { makeReport(days: 365) }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Duo.ink).offset(y: 2)
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.white)
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Duo.ink, lineWidth: 2))
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Duo.ink)
                        }
                        .frame(width: 34, height: 34)
                    }
                }

                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(metric.weeklyTrend.enumerated()), id: \.offset) { _, v in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Duo.green)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Duo.ink, lineWidth: 1))
                            .frame(height: CGFloat(max(2, v)) / 7.0 * 30 + 4)
                            .frame(maxWidth: .infinity)
                    }
                    Text("\(metric.last7DaysActive)/7")
                        .font(Duo.Fnt.ebd(11))
                        .foregroundColor(Duo.muted)
                        .frame(width: 34)
                }
                .frame(height: 36)

                HStack(spacing: 8) {
                    careChip(.brushHead, LocalizedStringKey("Brush head"), "🪥")
                    careChip(.dentist, LocalizedStringKey("Dentist"), "🦷")
                }
            }
        }
        .sheet(item: $shareItem) { payload in
            ShareSheet(items: [payload.url])
        }
    }

    private func slotDot(_ symbol: String, _ done: Bool) -> some View {
        Image(systemName: done ? symbol : "circle.dotted")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(done ? Duo.green : Duo.muted)
    }

    @ViewBuilder
    private func careChip(_ kind: CareKind, _ label: LocalizedStringKey, _ icon: String) -> some View {
        let s = care.status(profile.id, kind)
        let (text, due): (String, Bool) = {
            guard let days = s.daysRemaining else { return (String(localized: "set baseline"), false) }
            if days < 0 { return (String(localized: "overdue \(-days)d"), true) }
            if s.isDue { return (String(localized: "due today"), true) }
            return (String(localized: "in \(days)d"), false)
        }()
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon).font(.system(size: 11))
                Text(label).font(Duo.Fnt.ebd(10)).foregroundColor(Duo.ink)
            }
            .lineLimit(1)
            HStack(spacing: 6) {
                Text(text)
                    .font(Duo.Fnt.sbd(10))
                    .foregroundColor(due ? Duo.red : Duo.muted)
                    .lineLimit(1)
                Button(s.daysRemaining == nil ? "Set" : "Done") {
                    care.markDone(profile.id, kind)
                    NotificationScheduler.shared.rescheduleCare(inputs: CareStore.shared.careInputs())
                }
                .font(Duo.Fnt.ebd(10))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Duo.green))
                .overlay(Capsule().stroke(Duo.ink, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(due ? Duo.yellow.opacity(0.35) : Duo.stoneLight.opacity(0.7)))
        .overlay(Capsule().stroke(Duo.ink.opacity(0.6), lineWidth: 1.5))
    }
}
