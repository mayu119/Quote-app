import SwiftUI

struct WallpaperPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var tempSelected: [String] = []
    
    // プレミアムな雰囲気を出すための2カラムレイアウト
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // ヘッダーテキスト
                        VStack(spacing: 8) {
                            Text("WALLPAPER")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .tracking(6)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("日々のインスピレーションを引き出す\n背景として使用する壁紙を選択してください。")
                                .font(.system(size: 13, weight: .light))
                                .lineSpacing(6)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 24)
                        

                        // グリッド
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(BackgroundService.backgrounds, id: \.self) { bg in
                                let isSelected = tempSelected.contains(bg)
                                let index = tempSelected.firstIndex(of: bg)
                                
                                Button(action: {
                                    toggleSelection(for: bg)
                                }) {
                                    ZStack {
                                        // 画像本体
                                        Image(bg)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 240) // 縦長の美しい比率
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .scaleEffect(isSelected ? 0.95 : 1.0)
                                            .opacity(isSelected ? 1.0 : 0.6)
                                        
                                        // 選択時のオーバーレイ
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                                                .frame(height: 240)
                                                .scaleEffect(0.95)
                                            
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .black))
                                                        .foregroundColor(.black)
                                                        .frame(width: 32, height: 32)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                                        .padding(16)
                                                }
                                            }
                                        }
                                    }
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
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("APPLY") {
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
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(tempSelected.isEmpty ? .white.opacity(0.2) : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(tempSelected.isEmpty ? Color.white.opacity(0.1) : Color.white)
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
}
