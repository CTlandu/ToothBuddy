import SwiftUI
import ToothBuddyCore

struct HistoryView: View {
    @StateObject private var store = BrushingStore.shared
    @StateObject private var gamification = GamificationStore.shared
    @StateObject private var profiles = ProfileStore.shared
    /// Spec 05 §6.1 — adult ⇒ no kid gamification (level/achievements), show the
    /// calm habit curve instead. Per-profile; a kid sibling is unaffected.
    private var isAdult: Bool { profiles.activeProfile?.mode == .adult }
    @State private var contentAppeared = false
    @State private var selectedAchievement: Achievement?

    var body: some View {
        List {
            if !isAdult {
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

            if isAdult, let pid = profiles.activeProfileID {
                Section {
                    HabitCurveView(records: store.records, profileID: pid)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)

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

            if !isAdult {
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
    }

    private var levelCard: some View {
        HStack(spacing: 12) {
            Image(systemName: gamification.levelSystemImage)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(symbolColor(for: gamification.levelSystemImage))
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 2) {
                Text("LEVEL \(gamification.level)")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textMuted)
                Text(gamification.levelTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.surfaceFrost)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.surfaceFrostBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var achievementsHeader: some View {
        Text("ACHIEVEMENTS")
            .font(.system(size: 12, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(Theme.textMuted)
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
                                Circle()
                                    .fill(unlocked
                                          ? Theme.startButtonStart.opacity(0.25)
                                          : Color.black.opacity(0.05))
                                    .frame(width: 54, height: 54)
                                Image(systemName: achievement.systemImage)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(unlocked
                                                     ? symbolColor(for: achievement.systemImage)
                                                     : .gray.opacity(0.3))
                                    .symbolRenderingMode(.hierarchical)
                                if unlocked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.startButtonEnd)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                        .padding(2)
                                }
                            }
                            .frame(width: 54, height: 54)

                            Text(achievement.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(unlocked ? Theme.textPrimary : Theme.textMuted)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 30, alignment: .top)
                        }
                        .frame(width: 84)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Theme.surfaceFrost)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            unlocked ? Theme.startButtonEnd.opacity(0.35) : Theme.surfaceFrostBorder,
                                            lineWidth: unlocked ? 1.5 : 1
                                        )
                                )
                        )
                        .shadow(color: unlocked ? Theme.startButtonEnd.opacity(0.12) : .clear, radius: 6, y: 3)
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
            .font(.system(size: 12, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(Theme.textMuted)
    }

    private var emptyRecordsPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textMuted)
            Text("No Records Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text("Start brushing from the Brush tab to see your history here.")
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var streakCard: some View {
        let streak = store.consecutiveDaysCount
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.orange)
                    Text("CURRENT STREAK")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(Theme.textMutedStrong)
                }
                Text("\(streak) Day\(streak == 1 ? "" : "s")")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color(red: 251/255, green: 191/255, blue: 36/255))
                    .symbolRenderingMode(.hierarchical)
                Text("Keep it up!")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textMutedStrong)
            }
        }
        .padding(16)
        .background(Theme.streakGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
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
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Theme.startButtonEnd)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surfaceFrost)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.surfaceFrostBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func recordRow(_ record: BrushingRecord) -> some View {
        HStack {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Theme.startButtonStart, Theme.startButtonEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "mouth.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.startDate, style: .time)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text(relativeDate(record.startDate))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDuration(record.durationSeconds))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accentBlue)
                StarRatingView(count: record.starCount, size: 14)
            }
        }
        .padding(14)
        .background(Theme.surfaceFrost)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.borderLight, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
            // SF Symbol hero
            ZStack {
                Circle()
                    .fill(unlocked
                          ? LinearGradient(colors: [Theme.startButtonStart.opacity(0.35),
                                                    Theme.startButtonEnd.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.black.opacity(0.06),
                                                    Color.black.opacity(0.04)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                Image(systemName: achievement.systemImage)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(iconColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)

            // Status badge
            HStack(spacing: 5) {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(unlocked ? "Unlocked!" : "Locked")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(0.5)
            }
            .foregroundColor(unlocked ? Theme.startButtonEnd : Theme.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(unlocked
                          ? Theme.startButtonStart.opacity(0.2)
                          : Color.black.opacity(0.06))
            )
            .padding(.bottom, 14)

            // Title
            Text(achievement.title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Description
            Text(achievement.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 6)

            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("PROGRESS")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                    Text(progress)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(unlocked ? Theme.startButtonEnd : Theme.textMuted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.07))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(unlocked
                                  ? LinearGradient(colors: [Theme.startButtonStart, Theme.startButtonEnd],
                                                   startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [Theme.textMuted.opacity(0.4),
                                                            Theme.textMuted.opacity(0.25)],
                                                   startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progressFraction)
                    }
                }
                .frame(height: 8)
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
                Label("Saving brushing to Apple Health", systemImage: "heart.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surfaceFrost))
            } else {
                Button {
                    requesting = true
                    Task {
                        authorized = await HealthExporter.shared.requestAuthorization()
                        requesting = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.text.square")
                        Text(requesting ? "Connecting…" : "Save brushing to Apple Health")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(Theme.textPrimary)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surfaceFrost))
                }
                .buttonStyle(.plain)
                .disabled(requesting)
            }
        }
    }
}
