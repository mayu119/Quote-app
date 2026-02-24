import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var showNotificationTimePicker = false
    @State private var tempNotificationTime: Date = Date()
    @Environment(\.dismiss) private var dismiss
    
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
    
    // MARK: - Sections
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("NOTIFICATIONS")
                .font(.system(size: 10, weight: .black))
                .tracking(4)
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 24) {
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
                    Button(action: {
                        tempNotificationTime = userSettings.notificationTime
                        showNotificationTimePicker = true
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
                    .sheet(isPresented: $showNotificationTimePicker) {
                        timePickerSheet
                    }
                }
            }
        }
    }
    
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
                    
                    Button(action: {
                        // Upgrade trigger
                    }) {
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
    
    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    DatePicker(
                        "",
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
            .navigationTitle("SELECT TIME")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showNotificationTimePicker = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        userSettings.updateNotificationTime(tempNotificationTime)
                        showNotificationTimePicker = false
                        
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
                    }) {
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
