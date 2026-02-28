import SwiftUI

struct HistoryView: View {
    @StateObject private var store = BrushingStore.shared
    @StateObject private var gamification = GamificationStore.shared
    @State private var contentAppeared = false

    var body: some View {
        List {
            Section {
                levelCard
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            Section {
                streakCard
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            Section {
                statsRow
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            Section(header: achievementsHeader) {
                achievementsRow
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

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
    }

    private var levelCard: some View {
        HStack(spacing: 12) {
            Text(gamification.levelEmoji)
                .font(.system(size: 36))
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
                    VStack(spacing: 6) {
                        Text(achievement.emoji)
                            .font(.system(size: 28))
                            .opacity(unlocked ? 1 : 0.3)
                            .grayscale(unlocked ? 0 : 1)
                        Text(achievement.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(unlocked ? Theme.textPrimary : Theme.textMuted)
                            .lineLimit(1)
                    }
                    .frame(width: 72)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.surfaceFrost)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(unlocked ? Theme.accentBlue.opacity(0.4) : Theme.surfaceFrostBorder, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 2)
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
                Text("CURRENT STREAK 🔥")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textMutedStrong)
                Text("\(streak) Day\(streak == 1 ? "" : "s")")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(spacing: 4) {
                Text("🏆")
                    .font(.system(size: 42))
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
            statCard(icon: "⏱️", value: avgFormatted, label: "Avg Duration")
            statCard(icon: "🦷", value: "\(store.records.count)", label: "Total Sessions")
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(icon)
                .font(.system(size: 22))
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
                    .overlay(Text("🦷").font(.system(size: 20)))
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
