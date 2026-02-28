import SwiftUI

struct HistoryView: View {
    @StateObject private var store = BrushingStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                streakCard
                statsRow
                recentSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.appBackground)
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
                .foregroundColor(.white)
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

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT SESSIONS")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textMuted)

            if store.records.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.textMuted)
                    Text("No Records Yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Start brushing from the Brush tab to see your history here.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(store.records) { record in
                    recordRow(record)
                }
            }
        }
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
                        .foregroundColor(.white)
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
