import SwiftUI

/// 設定画面
struct SettingsView: View {
    // MARK: - Environment

    @EnvironmentObject private var userSettings: UserSettings

    @State private var showNotificationTimePicker = false
    @State private var tempNotificationTime: Date = Date()

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 通知設定セクション
                        notificationSection

                        // プレミアムセクション
                        premiumSection

                        // その他セクション
                        otherSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Sections

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("通知設定")
                .font(.headline)
                .foregroundColor(.white)

            // 通知ON/OFF
            HStack {
                Text("毎日の通知")
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $userSettings.notificationEnabled)
                    .labelsHidden()
                    .tint(accentGold)
                    .onChange(of: userSettings.notificationEnabled) { _, newValue in
                        handleNotificationToggle(newValue)
                    }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )

            // 通知時間設定
            if userSettings.notificationEnabled {
                Button(action: {
                    tempNotificationTime = userSettings.notificationTime
                    showNotificationTimePicker = true
                }) {
                    HStack {
                        Text("通知時間")
                            .foregroundColor(.white)

                        Spacer()

                        Text(formatTime(userSettings.notificationTime))
                            .foregroundColor(accentGold)

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .sheet(isPresented: $showNotificationTimePicker) {
                    timePickerSheet
                }
            }
        }
    }

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("プレミアム")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(accentGold)

                    if userSettings.isPremiumUser {
                        Text("プレミアム会員")
                            .foregroundColor(.white)
                    } else {
                        Text("無料プラン")
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if userSettings.isPremiumUser {
                        Text("有効")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.2))
                            )
                    }
                }

                if !userSettings.isPremiumUser {
                    Divider()
                        .background(Color.white.opacity(0.2))

                    Text("プレミアムで全ての名言を無制限で閲覧")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Button(action: {
                        // プレミアム購入画面へ
                    }) {
                        Text("プレミアムにアップグレード")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }

    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("その他")
                .font(.headline)
                .foregroundColor(.white)

            // アプリバージョン
            HStack {
                Text("バージョン")
                    .foregroundColor(.white)

                Spacer()

                Text("1.0.0")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )

            // プライバシーポリシー
            Button(action: {
                // プライバシーポリシーを開く
            }) {
                HStack {
                    Text("プライバシーポリシー")
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }

            // 利用規約
            Button(action: {
                // 利用規約を開く
            }) {
                HStack {
                    Text("利用規約")
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }

    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    DatePicker(
                        "通知時間",
                        selection: $tempNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("通知時間")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showNotificationTimePicker = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        userSettings.updateNotificationTime(tempNotificationTime)
                        showNotificationTimePicker = false

                        // 通知を再スケジュール
                        Task {
                            let calendar = Calendar.current
                            let hour = calendar.component(.hour, from: tempNotificationTime)
                            let minute = calendar.component(.minute, from: tempNotificationTime)

                            try? await NotificationService.shared.scheduleDailyQuoteNotification(
                                hour: hour,
                                minute: minute,
                                notificationHook: nil
                            )
                        }
                    }
                    .foregroundColor(accentGold)
                }
            }
            .preferredColorScheme(.dark)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Methods

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: userSettings.notificationTime)
                let minute = calendar.component(.minute, from: userSettings.notificationTime)

                try? await NotificationService.shared.scheduleDailyQuoteNotification(
                    hour: hour,
                    minute: minute,
                    notificationHook: nil
                )
            }
        } else {
            NotificationService.shared.cancelDailyQuoteNotification()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(UserSettings())
}
