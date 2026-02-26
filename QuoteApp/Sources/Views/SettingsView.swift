import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings

    @State private var showTimePicker = false
    @State private var tempTime: Date = Date()
    @State private var editingSlot: TimeSlot = .single
    @Environment(\.dismiss) private var dismiss

    /// どの通知時刻スロットを編集中か
    enum TimeSlot: Equatable {
        case single
        case premium(Int)
    }

    private let premiumSlotLabels = ["Morning", "Afternoon", "Evening"]
    private let premiumSlotIcons  = ["sunrise.fill", "sun.max.fill", "moon.stars.fill"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 64) {
                        notificationSection
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
            .navigationTitle("SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("NOTIFICATIONS")
                .font(.system(size: 10, weight: .black))
                .tracking(4)
                .foregroundColor(.white.opacity(0.3))

            VStack(spacing: 24) {
                // Toggle
                HStack {
                    Text("Daily Delivery")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $userSettings.notificationEnabled)
                        .labelsHidden()
                        .tint(.white)
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
    }

    // MARK: - Single Time Row (Free)

    private var singleTimeRow: some View {
        Button(action: {
            editingSlot = .single
            tempTime = userSettings.notificationTime
            showTimePicker = true
        }) {
            HStack {
                Text("Delivery Time")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white)
                Spacer()
                Text(formatTime(userSettings.notificationTime))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Premium Time Slots (3x)

    private var premiumTimeSlotsView: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow.opacity(0.7))
                Text("PREMIUM DELIVERY")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.4))
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
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)

                Text(premiumSlotLabels[index])
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white)

                Spacer()

                Text(formatTime(time))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Time Picker Sheet

    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    DatePicker(
                        "",
                        selection: $tempTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

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
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: confirmTimePick) {
                        Text("SET")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var pickerTitle: String {
        switch editingSlot {
        case .single: return "SELECT TIME"
        case .premium(let i): return premiumSlotLabels[i].uppercased()
        }
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("ACCESS")
                .font(.system(size: 10, weight: .black))
                .tracking(4)
                .foregroundColor(.white.opacity(0.3))

            if userSettings.isPremiumUser {
                HStack {
                    Text("Premium Status")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white)
                    Spacer()
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Unlock unlimited archive viewing.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.6))

                    Button(action: {}) {
                        Text("UPGRADE TO PREMIUM")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.white)
                    }
                }
            }
        }
    }

    // MARK: - About / System

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("SYSTEM")
                .font(.system(size: 10, weight: .black))
                .tracking(4)
                .foregroundColor(.white.opacity(0.3))

            VStack(spacing: 24) {
                HStack {
                    Text("Version")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }

                NavigationLink(destination: Text("Privacy Policy Details...")) {
                    HStack {
                        Text("Privacy Policy")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }

                NavigationLink(destination: Text("Terms of Service Details...")) {
                    HStack {
                        Text("Terms of Service")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
        }
    }

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("🛠️ DEBUG MODE")
                .font(.system(size: 10, weight: .black))
                .tracking(4)
                .foregroundColor(.yellow.opacity(0.8))

            VStack(spacing: 24) {
                HStack {
                    Text("Premium Mode (Pilot)")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $userSettings.isPremiumUser)
                        .labelsHidden()
                        .tint(.yellow)
                }

                if userSettings.isPremiumUser {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                        Text("All premium features unlocked")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                }
            }
        }
    }
    #endif

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
