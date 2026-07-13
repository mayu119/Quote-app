import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var quotes: [Quote] = []
    @State private var isLoading = true
    @State private var showPremiumView = false

    private let accentRose = WFM.ColorToken.nightRose
    private let ink = WFM.ColorToken.nightTextPrimary

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [WFM.ColorToken.nightRaised, WFM.ColorToken.nightHigh, WFM.ColorToken.nightBase],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if !userSettings.isPremiumUser {
                    lockedStateView
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentRose))
                        .scaleEffect(1.2)
                } else if quotes.isEmpty {
                    Text("まだ過去の言葉はありません。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ink.opacity(0.56))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 40) {
                            ForEach(quotes, id: \.id) { quote in
                                MinimalArchiveCard(quote: quote)
                            }
                        }
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("アーカイブ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(WFM.ColorToken.nightRaised, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if userSettings.isPremiumUser {
                    loadQuotes()
                }
            }
            .fullScreenCover(isPresented: $showPremiumView) {
                PremiumView(context: .archive)
            }
        }
    }
    
    private var lockedStateView: some View {
        VStack(spacing: 40) {
            Image(systemName: "lock")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(accentRose.opacity(0.6))
            
            Text("プレミアムでアーカイブ解放")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ink)
            
            Button(action: {
                showPremiumView = true
            }) {
                Text("アーカイブを見る")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(WFM.ColorToken.nightInk)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(accentRose)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal, 28)
    }
    
    private func loadQuotes() {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<Quote>(
                sortBy: [SortDescriptor(\.lastShownDate, order: .reverse)]
            )
            quotes = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            print("⚠️ Error loading: \(error)")
            isLoading = false
        }
    }
}

struct MinimalArchiveCard: View {
    let quote: Quote
    private let accentRose = WFM.ColorToken.nightRose
    private let ink = WFM.ColorToken.nightTextPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let lastShown = quote.lastShownDate {
                    Text(formatDate(lastShown))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ink.opacity(0.5))
                }
                Spacer()
            }
            
            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W6", size: 18))
                .foregroundColor(ink)
                .lineSpacing(8)
                .lineLimit(4)
            
            if quote.hasVisibleAuthorAttribution {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(accentRose.opacity(0.5))
                        .frame(width: 20, height: 1)
                    
                    Text(quote.displayAuthor)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(ink.opacity(0.56))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: accentRose.opacity(0.10), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

struct CalendarShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSettings: UserSettings

    @State private var favoriteQuotes: [Quote] = []
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var isLoading = true

    private let accentRose = WFM.ColorToken.nightRose
    private let accentPeach = WFM.ColorToken.nightRoseSoft
    private let ink = WFM.ColorToken.nightTextPrimary
    private let mutedInk = WFM.ColorToken.nightTextSub
    private let inkOnRose = WFM.ColorToken.nightInk

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [WFM.ColorToken.nightRaised, WFM.ColorToken.nightHigh, WFM.ColorToken.nightBase],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentRose))
                        .scaleEffect(1.15)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            if let todayWordSelection = userSettings.todayWordSelection {
                                todayWordCard(todayWordSelection)
                            }

                            monthHeader
                            weekdayHeader
                            monthGrid

                            if favoriteQuotes.isEmpty {
                                emptyState
                            } else {
                                selectedDaySection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("言葉のカレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(WFM.ColorToken.nightRaised, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
            .task {
                loadFavorites()
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button(action: { shiftMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ink)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 4) {
                Text(monthTitle(selectedMonth))
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(ink)

                Text("その日に残した言葉が見える")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(mutedInk)
            }

            Spacer()

            Button(action: { shiftMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ink)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(mutedInk)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
    }

    private var monthGrid: some View {
        let days = daysForMonthGrid(selectedMonth)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 48)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let count = quotes(on: date).count
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)

        return Button(action: {
            selectedDate = date
        }) {
            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? inkOnRose : (isCurrentMonth ? ink : mutedInk.opacity(0.45)))

                Group {
                    if count > 0 {
                        HStack(spacing: 3) {
                            ForEach(0..<min(count, 3), id: \.self) { _ in
                                Circle()
                                    .fill(isSelected ? inkOnRose.opacity(0.85) : accentRose)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accentRose : Color.white.opacity(count > 0 ? 0.13 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? accentRose.opacity(0.6) : Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: accentRose.opacity(isSelected ? 0.22 : 0.0), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var selectedDaySection: some View {
        let effectiveDate = selectedDate ?? latestFavoriteDate ?? Date()
        let dayQuotes = quotes(on: effectiveDate)

        return VStack(alignment: .leading, spacing: 14) {
            Text(daySectionTitle(effectiveDate))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ink)

            if dayQuotes.isEmpty {
                Text("この日はまだ言葉を残していません。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(mutedInk)
                    .padding(.top, 2)
            } else {
                ForEach(dayQuotes, id: \.id) { quote in
                    dayQuoteCard(quote)
                }
            }
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(accentRose.opacity(0.55))

            Text("まだ日付に残した言葉はありません")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ink)

            Text("気になった言葉を棚に置いていくと、日付ごとに自分の流れが見えてきます。")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(mutedInk)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func todayWordCard(_ selection: TodayWordSelection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY'S WORD")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(2.4)
                .foregroundColor(accentRose.opacity(0.82))

            Text(selection.punchline)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ink)
                .lineSpacing(4)

            HStack(spacing: 10) {
                Text("今日の私の言葉")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(mutedInk)

                Text(selection.author)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(mutedInk.opacity(0.78))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.10), accentPeach.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentRose.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: accentRose.opacity(0.12), radius: 16, x: 0, y: 10)
    }

    private func dayQuoteCard(_ quote: Quote) -> some View {
        let isTodayWord = userSettings.todayWordSelection?.quoteID == quote.id

        return VStack(alignment: .leading, spacing: 12) {
            if isTodayWord {
                Text("今日の私の言葉")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(2.2)
                    .foregroundColor(accentRose.opacity(0.88))
            }

            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W6", size: 17))
                .foregroundColor(ink)
                .lineSpacing(7)

            if let note = quote.favoriteNote, !note.isEmpty {
                Text(note)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(mutedInk)
                    .lineSpacing(4)
            }

            if quote.hasVisibleAuthorAttribution {
                HStack(spacing: 10) {
                    Rectangle()
                        .fill(accentRose.opacity(0.5))
                        .frame(width: 18, height: 1)
                    Text(quote.displayAuthor)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(mutedInk)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: accentRose.opacity(0.08), radius: 12, x: 0, y: 8)
    }

    private func loadFavorites() {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<Quote>(
                predicate: #Predicate { $0.isFavorited == true },
                sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
            )
            favoriteQuotes = try modelContext.fetch(descriptor)
            if selectedDate == nil {
                selectedDate = latestFavoriteDate
            }
            if let selectedDate {
                selectedMonth = selectedDate
            }
        } catch {
            favoriteQuotes = []
        }
        isLoading = false
    }

    private var latestFavoriteDate: Date? {
        favoriteQuotes.compactMap(\.favoritedAt).max()
    }

    private func quotes(on date: Date) -> [Quote] {
        favoriteQuotes.filter { quote in
            guard let favoritedAt = quote.favoritedAt else { return false }
            return calendar.isDate(favoritedAt, inSameDayAs: date)
        }
    }

    private func shiftMonth(by value: Int) {
        selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    private func daySectionTitle(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "今日の棚"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: date)) に残した言葉"
    }

    private func daysForMonthGrid(_ date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: lastDay) else {
            return []
        }

        var days: [Date?] = []
        var current = firstWeekInterval.start

        while current < lastWeekInterval.end {
            if calendar.isDate(current, equalTo: date, toGranularity: .month) {
                days.append(current)
            } else {
                days.append(nil)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return days
    }
}
