import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings

    @State private var showTimePicker = false
    @State private var tempTime: Date = Date()
    @State private var editingSlot: TimeSlot = .single
    @State private var showPremiumWall = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // Legal URLs
    private let termsURL = URL(string: "https://mayu119.github.io/Quote-app/terms.html")!
    private let privacyURL = URL(string: "https://mayu119.github.io/Quote-app/privacy.html")!

    /// どの通知時刻スロットを編集中か
    enum TimeSlot: Equatable {
        case single
        case premium(Int)
    }

    private let premiumSlotLabels = ["朝", "昼", "夜"]
    private let premiumSlotIcons  = ["sunrise.fill", "sun.max.fill", "moon.stars.fill"]
    private let accentRose = Color(red: 0.86, green: 0.55, blue: 0.60)
    private let accentPeach = Color(red: 0.95, green: 0.79, blue: 0.68)
    private let cardFill = Color.white.opacity(0.84)
    private let ink = Color(red: 0.31, green: 0.24, blue: 0.24)
    private let subInk = Color(red: 0.50, green: 0.42, blue: 0.40)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.95, blue: 0.93),
                        Color(red: 0.98, green: 0.91, blue: 0.90),
                        Color(red: 0.95, green: 0.94, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 64) {
                        if !userSettings.isPremiumUser {
                            premiumEntryCard
                        }
                        notificationSection
                        liveActivitySection
                        displaySection
                        premiumSection
                        aboutSection
                        #if DEBUG
                        debugSection
                        #endif
                        Spacer(minLength: 64)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.98, green: 0.94, blue: 0.93), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(subInk)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView()
                .environmentObject(userSettings)
        }
    }

    private var premiumEntryCard: some View {
        Button(action: {
            showPremiumWall = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PREMIUM")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(subInk)
                        Text("プレミアムプランを見る")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ink)
                        Text("年額プラン・月額プラン・購入復元はここから確認できます。")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(subInk)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(accentRose)
                }

                HStack {
                    Text("プランを開く")
                        .font(.system(size: 13, weight: .black))
                        .tracking(2)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(accentRose)
                .clipShape(Capsule())
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.white, Color(red: 1.0, green: 0.96, blue: 0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: accentRose.opacity(0.14), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionTitle("通知")

            VStack(spacing: 24) {
                // Toggle
                HStack {
                    Text("毎日の名言配信")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(ink)
                    Spacer()
                    Toggle("", isOn: $userSettings.notificationEnabled)
                        .labelsHidden()
                        .tint(accentRose)
                        .onChange(of: userSettings.notificationEnabled) { _, newValue in
                            handleNotificationToggle(newValue)
                        }
                }

                if userSettings.notificationEnabled {
                    if userSettings.isPremiumUser {
                        // プレミアム: 朝・昼・夜 3スロット
                        premiumTimeSlotsView
                    } else {
                        // 無料: シングル時刻
                        singleTimeRow
                    }
                }
            }
        }
        .sheet(isPresented: $showTimePicker) {
            timePickerSheet
        }
        .padding(24)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Live Activity Section
    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionTitle("ロック画面")

            VStack(spacing: 24) {
                HStack {
                    ZStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Activityの表示")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(ink)
                            Text("常に名言をロック画面に表示します")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(subInk)
                        }
                        
                        if !userSettings.isPremiumUser {
                            Color.black.opacity(0.001) // タップ領域確保
                                .onTapGesture {
                                    // プレミアムへの誘導を入れるか、そのまま無効化しておく
                                }
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $userSettings.liveActivityEnabled)
                        .labelsHidden()
                        .tint(accentRose)
                        .disabled(!userSettings.isPremiumUser) // 無料版は切り替えできないようにする
                        .onChange(of: userSettings.liveActivityEnabled) { _, newValue in
                            if !newValue {
                                NotificationService.shared.cancelDynamicLockScreenActivity()
                            }
                        }
                }
            }
        }
        .padding(24)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Single Time Row (Free)

    private var singleTimeRow: some View {
        Button(action: {
            editingSlot = .single
            tempTime = userSettings.notificationTime
            showTimePicker = true
        }) {
            HStack {
                Text("配信時間")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(ink)
                Spacer()
                Text(formatTime(userSettings.notificationTime))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(accentRose)
            }
        }
    }

    // MARK: - Premium Time Slots (3x)

    private var premiumTimeSlotsView: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                    .foregroundColor(accentRose.opacity(0.8))
                Text("プレミアム配信")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(subInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(0..<3, id: \.self) { index in
                premiumSlotRow(index: index)
            }
        }
    }

    private func premiumSlotRow(index: Int) -> some View {
        let time = index < userSettings.premiumNotificationTimes.count
            ? userSettings.premiumNotificationTimes[index]
            : Date()

        return Button(action: {
            editingSlot = .premium(index)
            tempTime = time
            showTimePicker = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: premiumSlotIcons[index])
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(subInk)
                    .frame(width: 20)

                Text(premiumSlotLabels[index])
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(ink)

                Spacer()

                Text(formatTime(time))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(accentRose)
            }
        }
    }

    // MARK: - Time Picker Sheet

    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.94, blue: 0.93).ignoresSafeArea()

                VStack {
                    DatePicker(
                        "",
                        selection: $tempTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.light)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(pickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showTimePicker = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(subInk)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: confirmTimePick) {
                        Text("設定")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundColor(accentRose)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var pickerTitle: String {
        switch editingSlot {
        case .single: return "時間を選択"
        case .premium(let i): return premiumSlotLabels[i].uppercased()
        }
    }

    // MARK: - Display Settings
    
    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionTitle("表示設定")

            VStack(spacing: 24) {
                HStack {
                    ZStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("テキストの縦書き表示")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(ink)
                            Text("名言を縦書きレイアウトで表示します")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(subInk)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $userSettings.isVerticalTextMode)
                        .labelsHidden()
                        .tint(accentRose)
                }
            }
        }
        .padding(24)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionTitle("プラン")

            if userSettings.isPremiumUser {
                HStack {
                    Text("ステータス")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(ink)
                    Spacer()
                    Text("有効 (PREMIUM)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(accentRose)
                        .clipShape(Capsule())
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("過去の名言を無制限に閲覧できます。")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(subInk)

                    Button(action: {
                        showPremiumWall = true
                    }) {
                        Text("プレミアムにアップグレード")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(accentRose)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(24)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - About / System

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionTitle("システム")

            VStack(spacing: 24) {
                HStack {
                    Text("バージョン")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(ink)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(subInk)
                }

                Button(action: { openURL(privacyURL) }) {
                    HStack {
                        Text("プライバシーポリシー")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(ink)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(subInk)
                    }
                }

                Button(action: { openURL(termsURL) }) {
                    HStack {
                        Text("利用規約")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(ink)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(subInk)
                    }
                }
            }
        }
        .padding(24)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("🛠️ デバッグモード")
                .font(.system(size: 12, weight: .black))
                .tracking(4)
                .foregroundColor(accentRose)

            VStack(spacing: 24) {
                HStack {
                    Text("プレミアムモード (テスト)")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(ink)
                    Spacer()
                    Toggle("", isOn: $userSettings.isPremiumUser)
                        .labelsHidden()
                        .tint(accentRose)
                }

                if userSettings.isPremiumUser {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentRose)
                        Text("すべてのプレミアム機能が解放されています")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(subInk)
                    }
                }
            }
        }
        .padding(24)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    #endif

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(subInk)
    }

    // MARK: - Actions

    private func confirmTimePick() {
        showTimePicker = false

        switch editingSlot {
        case .single:
            userSettings.updateNotificationTime(tempTime)
        case .premium(let index):
            userSettings.updatePremiumNotificationTime(at: index, to: tempTime)
        }

        scheduleNotifications()
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            scheduleNotifications()
        } else {
            NotificationService.shared.cancelAllQuoteNotifications()
        }
    }

    /// 現在の設定に基づいて通知を再スケジュール（保存済み名言を使用）
    private func scheduleNotifications() {
        let savedQuotes = NotificationService.shared.loadSavedNotificationQuotes()
        Task {
            if userSettings.isPremiumUser {
                try? await NotificationService.shared.schedulePremiumNotifications(
                    times: userSettings.premiumNotificationTimes,
                    quotes: savedQuotes
                )
            } else {
                let cal = Calendar.current
                let h = cal.component(.hour, from: userSettings.notificationTime)
                let m = cal.component(.minute, from: userSettings.notificationTime)
                try? await NotificationService.shared.scheduleDailyNotification(
                    hour: h, minute: m,
                    quote: savedQuotes.first
                )
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
