import SwiftUI

struct WallpaperPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSettings: UserSettings

    let onPremiumRequired: () -> Void
    @State private var tempSelected: [String] = []

    // プレミアムな雰囲気を出すための2カラムレイアウト
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    private let accentRose = WFM.ColorToken.nightRose
    private let ink = WFM.ColorToken.nightTextPrimary
    private let cardHeight: CGFloat = 232

    private var availableBackgrounds: [String] {
        BackgroundService.backgrounds.filter { UIImage(named: $0) != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [WFM.ColorToken.nightRaised, WFM.ColorToken.nightHigh, WFM.ColorToken.nightBase],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // ヘッダーテキスト
                        VStack(spacing: 8) {
                            Text("背景をえらぶ")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(ink)
                            
                            Text("日々のインスピレーションを引き出す\n背景として使用する壁紙を選択してください。")
                                .font(.system(size: 13, weight: .medium))
                                .lineSpacing(6)
                                .multilineTextAlignment(.center)
                                .foregroundColor(ink.opacity(0.62))
                        }
                        .padding(.top, 24)
                        

                        // グリッド
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(availableBackgrounds, id: \.self) { bg in
                                let isSelected = tempSelected.contains(bg)

                                Button(action: {
                                    if userSettings.isPremiumUser {
                                        toggleSelection(for: bg)
                                    } else {
                                        onPremiumRequired()
                                    }
                                }) {
                                    ZStack {
                                        // 画像本体
                                        Image(bg)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: cardHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .scaleEffect(isSelected ? 0.95 : 1.0)
                                            .opacity(isSelected ? 1.0 : 0.6)
                                            .overlay(alignment: .topLeading) {
                                                wallpaperLabel(for: bg, isSelected: isSelected)
                                            }

                                        // 選択時のオーバーレイ
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                                                .frame(height: cardHeight)
                                                .scaleEffect(0.95)

                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .black))
                                                        .foregroundColor(.white)
                                                        .frame(width: 32, height: 32)
                                                        .background(accentRose)
                                                        .clipShape(Circle())
                                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                                        .padding(16)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ink)
                            .padding(8)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("適用") {
                        guard userSettings.isPremiumUser else {
                            onPremiumRequired()
                            return
                        }

                        if !tempSelected.isEmpty {
                            userSettings.selectedBackgrounds = tempSelected
                            // Analytics: 壁紙変更
                            if let bg = tempSelected.first {
                                AnalyticsService.shared.logWallpaperChange(
                                    wallpaperName: bg,
                                    isPremium: userSettings.isPremiumUser
                                )
                            }
                        }
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(tempSelected.isEmpty ? ink.opacity(0.3) : WFM.ColorToken.nightInk)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(tempSelected.isEmpty ? Color.white.opacity(0.08) : accentRose)
                    .clipShape(Capsule())
                    .disabled(tempSelected.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            tempSelected = userSettings.selectedBackgrounds
        }
    }
    
    private func toggleSelection(for bg: String) {
        if tempSelected.contains(bg) { return } // 既に選ばれていたら何もしない
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        tempSelected = [bg] // 単一選択にする
    }

    private func wallpaperLabel(for background: String, isSelected: Bool) -> some View {
        Text(backgroundLabel(for: background))
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white.opacity(0.94))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(isSelected ? 0.36 : 0.24))
            .clipShape(Capsule())
            .padding(12)
    }

    private func backgroundLabel(for name: String) -> String {
        name
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
