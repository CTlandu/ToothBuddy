import SwiftUI
import ToothBuddyCore

struct HistoryView: View {
    @StateObject private var store = BrushingStore.shared
    @StateObject private var gamification = GamificationStore.shared
    @StateObject private var profiles = ProfileStore.shared
    @StateObject private var prefs = PreferencesStore.shared
    @State private var contentAppeared = false
    @State private var selectedAchievement: Achievement?
    @State private var shareURL: URL?

    var body: some View {
        List {
            if prefs.showLevelAchievements {
                Section {
                    levelCard
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
            }

            Section {
                streakCard
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            if prefs.showHabitCurve, let pid = profiles.activeProfileID {
                Section {
                    HabitCurveView(records: store.records, profileID: pid)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
            }

            if prefs.healthConnectEnabled {
                Section {
                    HealthConnectRow()
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
            }

            Section {
                statsRow
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            Section {
                shareReportButton
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            if prefs.showLevelAchievements {
                Section(header: achievementsHeader) {
                    achievementsRow
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
            }

            Section(header: recentSessionsHeader) {
                if store.records.isEmpty {
                    emptyRecordsPlaceholder
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(store.records) { record in
                        recordRow(record)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    store.deleteRecord(id: record.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 18)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                contentAppeared = true
            }
        }
        .animation(.easeOut(duration: 0.3), value: store.records.count)
        .onAppear {
            gamification.checkAndUnlock(records: store.records)
        }
        .sheet(item: $selectedAchievement) { achievement in
            let unlocked = gamification.unlockedAchievementIds.contains(achievement.id)
            AchievementDetailSheet(
                achievement: achievement,
                unlocked: unlocked,
                progress: gamification.progressDescription(for: achievement, records: store.records),
                iconColor: unlocked ? symbolColor(for: achievement.systemImage) : .gray.opacity(0.3)
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(get: { shareURL != nil },
                                    set: { if !$0 { shareURL = nil } })) {
            if let url = shareURL { ShareSheet(items: [url]) }
        }
    }

    /// U15 — build a 90-day dentist-proof PDF for the owner and present the share sheet.
    private var shareReportButton: some View {
        Button {
            let cal = Calendar.current
            let end = Date()
            let start = cal.date(byAdding: .day, value: -89, to: end) ?? end
            guard let pid = profiles.activeProfileID else { return }
            let data = ReportBuilder.build(
                profileID: pid, profileName: profiles.activeProfile?.name ?? "Me",
                in: store.records, start: start, end: end, now: end,
                config: .default, calendar: cal)
            shareURL = ReportPDFRenderer.writeTempPDF(data)
        } label: {
            DuoCard(padding: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Duo.blue)
                    Text("Share dentist report (90 days)")
                        .font(Duo.Fnt.ebd(14))
                        .foregroundColor(Duo.ink)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Duo.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var levelCard: some View {
        DuoCard(padding: 16) {
            HStack(spacing: 14) {
                // Buddy as the level avatar
                BuddyView()
                    .frame(width: 44, height: 50)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("LEVEL \(gamification.level)")
                            .font(Duo.Fnt.ebd(11))
                            .tracking(1)
                            .foregroundColor(Duo.muted)
                        DuoBadge(text: "+ XP",
                                 leadingEmoji: "✨",
                                 role: .warning)
                    }
                    Text(gamification.levelTitle)
                        .font(Duo.Fnt.ebd(18))
                        .foregroundColor(Duo.ink)
                }
                Spacer()
            }
        }
    }

    private var achievementsHeader: some View {
        Text("ACHIEVEMENTS")
            .font(Duo.Fnt.ebd(12))
            .tracking(1.2)
            .foregroundColor(Duo.muted)
    }

    private var achievementsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GamificationStore.allAchievements) { achievement in
                    let unlocked = gamification.unlockedAchievementIds.contains(achievement.id)
                    Button {
                        selectedAchievement = achievement
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                // Inner chunky circle medal
                                Circle()
                                    .fill(unlocked ? Duo.yellowShadow : Duo.stoneLight.opacity(0.5))
                                    .frame(width: 54, height: 54)
                                    .offset(y: 3)
                                Circle()
                                    .fill(unlocked ? Duo.yellow : Duo.stoneLight)
                                    .overlay(Circle().stroke(Duo.ink, lineWidth: 2))
                                    .frame(width: 54, height: 54)
                                Image(systemName: achievement.systemImage)
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(unlocked ? Duo.ink : Duo.muted.opacity(0.5))
                                if unlocked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundColor(Duo.green)
                                        .background(Circle().fill(.white))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                        .padding(2)
                                }
                            }
                            .frame(width: 54, height: 60)

                            Text(achievement.title)
                                .font(Duo.Fnt.ebd(11))
                                .foregroundColor(unlocked ? Duo.ink : Duo.muted)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 30, alignment: .top)
                        }
                        .frame(width: 88)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 6)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Duo.ink)
                                    .offset(y: 4)
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Duo.ink, lineWidth: 2)
                                    )
                            }
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private var recentSessionsHeader: some View {
        Text("RECENT SESSIONS")
            .font(Duo.Fnt.ebd(12))
            .tracking(1.2)
            .foregroundColor(Duo.muted)
    }

    private var emptyRecordsPlaceholder: some View {
        VStack(spacing: 14) {
            BuddyView()
                .frame(width: 96, height: 110)
                .opacity(0.55)
            Text("No records yet")
                .font(Duo.Fnt.ebd(18))
                .foregroundColor(Duo.ink)
            Text("Tap Brush below to start your first session.")
                .font(Duo.Fnt.sbd(13))
                .foregroundColor(Duo.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var streakCard: some View {
        let streak = store.consecutiveDaysCount
        // Duolingo's streak card is bright orange-yellow chunky — face = Duo.yellow
        return DuoCard(face: Duo.yellow, padding: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 16))
                        Text("CURRENT STREAK")
                            .font(Duo.Fnt.ebd(11))
                            .tracking(1)
                            .foregroundColor(Duo.ink.opacity(0.7))
                    }
                    Text("\(streak)")
                        .font(Duo.Fnt.ebd(48))
                        .foregroundColor(Duo.ink)
                    Text(streak == 1 ? "day" : "days")
                        .font(Duo.Fnt.ebd(14))
                        .foregroundColor(Duo.ink.opacity(0.75))
                }
                Spacer()
                VStack(spacing: 4) {
                    Text("🏆")
                        .font(.system(size: 40))
                    Text("Keep it up!")
                        .font(Duo.Fnt.ebd(11))
                        .foregroundColor(Duo.ink.opacity(0.7))
                }
            }
        }
    }

    private var statsRow: some View {
        let avgSeconds = store.averageDurationSeconds
        let avgFormatted = formattedDuration(avgSeconds)
        return HStack(spacing: 10) {
            statCard(systemImage: "timer", value: avgFormatted, label: "Avg Duration")
            statCard(systemImage: "mouth.fill", value: "\(store.records.count)", label: "Total Sessions")
        }
    }

    private func statCard(systemImage: String, value: String, label: String) -> some View {
        DuoCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Duo.green)
                Text(value)
                    .font(Duo.Fnt.ebd(20))
                    .foregroundColor(Duo.ink)
                Text(label.uppercased())
                    .font(Duo.Fnt.ebd(10))
                    .tracking(0.6)
                    .foregroundColor(Duo.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func recordRow(_ record: BrushingRecord) -> some View {
        DuoCard(padding: 14) {
            HStack {
                HStack(spacing: 12) {
                    // Duolingo-style chunky outlined icon tile
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Duo.greenShadow)
                            .frame(width: 44, height: 44)
                            .offset(y: 3)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Duo.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Duo.ink, lineWidth: 2)
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "mouth.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 47)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.startDate, style: .time)
                            .font(Duo.Fnt.ebd(15))
                            .foregroundColor(Duo.ink)
                        Text(relativeDate(record.startDate))
                            .font(Duo.Fnt.sbd(12))
                            .foregroundColor(Duo.muted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedDuration(record.durationSeconds))
                        .font(Duo.Fnt.ebd(18))
                        .foregroundColor(Duo.green)
                    StarRatingView(count: record.starCount, size: 14)
                }
            }
        }
    }

    private func formattedDuration(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Achievement detail modal

private struct AchievementDetailSheet: View {
    let achievement: Achievement
    let unlocked: Bool
    let progress: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 0) {
            // Chunky hero — ink-bordered circle with offset shadow
            ZStack {
                Circle().fill(Duo.ink).offset(y: 4)
                Circle()
                    .fill(unlocked ? Duo.yellow.opacity(0.5) : Duo.stoneLight)
                    .overlay(Circle().stroke(Duo.ink, lineWidth: 2))
                Image(systemName: achievement.systemImage)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(iconColor)
            }
            .frame(width: 96, height: 96)
            .padding(.top, 28)
            .padding(.bottom, 16)

            // Status badge — chunky capsule
            ZStack {
                Capsule().fill(unlocked ? Duo.greenShadow : Duo.ink.opacity(0.5))
                    .offset(y: 2)
                HStack(spacing: 5) {
                    Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(unlocked ? "Unlocked!" : "Locked")
                        .font(Duo.Fnt.ebd(12))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(unlocked ? Duo.green : Duo.muted))
                .overlay(Capsule().stroke(Duo.ink, lineWidth: 1.5))
            }
            .fixedSize()
            .padding(.bottom, 14)

            // Title
            Text(achievement.title)
                .font(Duo.Fnt.ebd(22))
                .foregroundColor(Duo.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Description
            Text(achievement.description)
                .font(Duo.Fnt.sbd(14))
                .foregroundColor(Duo.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)

            // Progress bar — chunky outlined
            VStack(spacing: 6) {
                HStack {
                    Text("PROGRESS")
                        .font(Duo.Fnt.ebd(10))
                        .tracking(1)
                        .foregroundColor(Duo.muted)
                    Spacer()
                    Text(progress)
                        .font(Duo.Fnt.ebd(12))
                        .foregroundColor(unlocked ? Duo.green : Duo.muted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Duo.stoneLight)
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .stroke(Duo.ink, lineWidth: 1.5))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(unlocked ? Duo.green : Duo.muted.opacity(0.4))
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .stroke(Duo.ink, lineWidth: 1.5))
                            .frame(width: max(8, geo.size.width * progressFraction))
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)

            Spacer()
        }
    }

    /// Parses "X / Y" progress string into a 0…1 fraction for the progress bar.
    private var progressFraction: CGFloat {
        let parts = progress.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2,
              let numerator = Double(parts[0].split(separator: " ").first ?? ""),
              let denominator = Double(parts[1].split(separator: " ").first ?? ""),
              denominator > 0
        else { return unlocked ? 1 : 0 }
        return CGFloat(min(numerator / denominator, 1.0))
    }
}

// MARK: - Adult Apple Health opt-in (Spec 05 §6.6)

/// Contextual, write-only Health opt-in. Tapping requests share-only authorization for
/// `toothbrushingEvent`. Never reads any health data; the local record stays the truth.
private struct HealthConnectRow: View {
    @State private var authorized = HealthExporter.shared.isAuthorized
    @State private var requesting = false

    var body: some View {
        Group {
            if !HealthExporter.shared.isAvailable {
                EmptyView()
            } else if authorized {
                DuoCard(face: Duo.blush.opacity(0.4), padding: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Duo.red)
                        Text("Saving brushing to Apple Health")
                            .font(Duo.Fnt.ebd(14))
                            .foregroundColor(Duo.ink)
                        Spacer()
                    }
                }
            } else {
                Button {
                    requesting = true
                    Task {
                        authorized = await HealthExporter.shared.requestAuthorization()
                        requesting = false
                    }
                } label: {
                    DuoCard(padding: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(Duo.red)
                            Text(requesting ? "Connecting…" : "Save brushing to Apple Health")
                                .font(Duo.Fnt.ebd(14))
                                .foregroundColor(Duo.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(Duo.muted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(requesting)
            }
        }
    }
}
