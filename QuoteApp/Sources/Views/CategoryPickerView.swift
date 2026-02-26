import SwiftUI

// MARK: - CategoryPickerView

/// グリッドカード形式のカテゴリ選択シート
/// 大カテゴリをセクションヘッダーとして表示し、配下の中カテゴリをカードグリッドで並べる
struct CategoryPickerView: View {

    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedMediumCategory: QuoteMediumCategory?
    @Binding var selectedLargeCategory: QuoteLargeCategory?

    /// カテゴリ選択時のコールバック
    var onSelect: (QuoteMediumCategory?, QuoteLargeCategory?) -> Void
    /// ロックされたカテゴリをタップ時に課金画面を表示させるコールバック
    var onPremiumRequired: () -> Void

    @State private var appear = false

    private let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .zIndex(10)

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 56) {
                        // 全カテゴリ（ランダム）
                        allRandomCard
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: appear)

                        // 大カテゴリごとのセクション
                        ForEach(Array(QuoteLargeCategory.allCases.enumerated()), id: \.element) { index, large in
                            largeCategorySection(large: large)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 30)
                                .animation(.easeOut(duration: 0.7).delay(Double(index) * 0.1 + 0.2), value: appear)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                appear = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .black))
                        Text("CLOSE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(3)
                    }
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("SECTOR")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(10)
                        .foregroundColor(accentGold)
                        .shadow(color: accentGold.opacity(0.3), radius: 8)
                    
                    Rectangle()
                        .fill(accentGold)
                        .frame(width: 24, height: 1)
                        .opacity(0.3)
                }

                Spacer()
                
                // バランス用
                Color.clear.frame(width: 70, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            
            Divider().background(Color.white.opacity(0.1))
        }
    }

    // MARK: - 全カテゴリ（ランダム）

    private var allRandomCard: some View {
        let isSelected = selectedMediumCategory == nil && selectedLargeCategory == nil
        return Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onSelect(nil, nil)
            dismiss()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? .black : accentGold.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(isSelected ? .white : accentGold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("全カテゴリ")
                        .font(.custom("HiraginoSans-W8", size: 18))
                    Text("UNIVERSE / ALL")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(3)
                        .opacity(isSelected ? 0.7 : 0.4)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(isSelected ? Color.white : Color.white.opacity(0.03))
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: isSelected ? .white.opacity(0.2) : .clear, radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 大カテゴリセクション

    private func largeCategorySection(large: QuoteLargeCategory) -> some View {
        let mediums = QuoteMediumCategory.allCases.filter { $0.largeCategory == large }
        let isLargeSelected = selectedLargeCategory == large && selectedMediumCategory == nil
        let isLocked = !userSettings.isPremiumUser

        return VStack(alignment: .leading, spacing: 24) {
            // セクションヘッダー（タップで大カテゴリ丸ごと選択）
            Button(action: {
                if isLocked {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    onPremiumRequired()
                } else {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSelect(nil, large)
                    dismiss()
                }
            }) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(large.displayName)
                        .font(.custom("HiraginoSans-W8", size: 28))
                        .foregroundColor(.white)

                    Text(large.displayEn)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .tracking(6)
                        .foregroundColor(accentGold.opacity(0.6))

                    Spacer()

                    if isLargeSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(accentGold)
                            .shadow(color: accentGold.opacity(0.5), radius: 6)
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.25))
                    } else {
                        Text("ALL")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(accentGold.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(accentGold.opacity(0.35), lineWidth: 1)
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            // カードグリッド
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(mediums, id: \.self) { medium in
                    mediumCategoryCard(medium: medium)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 中カテゴリカード

    private func mediumCategoryCard(medium: QuoteMediumCategory) -> some View {
        let isSelected = selectedMediumCategory == medium
        let freeCategory = userSettings.currentFreeMediumCategory
        let isLocked = !userSettings.isPremiumUser && medium != freeCategory
        let isFreeToday = !userSettings.isPremiumUser && medium == freeCategory

        return Button(action: {
            if isLocked {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                onPremiumRequired()
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSelect(medium, nil)
                dismiss()
            }
        }) {
            ZStack(alignment: .bottomLeading) {
                // 背景
                RoundedRectangle(cornerRadius: 2)
                    .fill(cardGradient(for: medium))
                
                // 質感
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(
                        colors: [.black.opacity(0.0), .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))

                // アイコン
                Image(systemName: symbolName(for: medium))
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundColor(isSelected ? accentGold.opacity(0.6) : .white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -15)

                // 選択時・バッジ
                VStack {
                    HStack {
                        if isSelected {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(accentGold)
                                .shadow(color: accentGold, radius: 4)
                        }
                        
                        Spacer()
                        
                        if isFreeToday {
                            Text("FREE")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .tracking(1)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(accentGold)
                                .cornerRadius(1)
                        } else if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    Spacer()
                }
                .padding(14)

                // カテゴリ名
                VStack(alignment: .leading, spacing: 4) {
                    Text(medium.displayTitleJa)
                        .font(.custom("HiraginoSans-W8", size: 15))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(medium.displayText.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .padding(14)

                // 選択中: ボーダーとグロウ
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(accentGold, lineWidth: 2)
                        .shadow(color: accentGold.opacity(0.5), radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                
                // ロック時の暗幕
                if isLocked {
                    Color.black.opacity(0.4)
                }
            }
            .frame(height: 140)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Card Gradient

    private func cardGradient(for medium: QuoteMediumCategory) -> LinearGradient {
        let (c1, c2) = cardColors(for: medium)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func cardColors(for medium: QuoteMediumCategory) -> (Color, Color) {
        switch medium.largeCategory {
        case .legends:
            switch medium {
            case .politiciansLeaders: return (Color(hex: "241E12"), Color(hex: "0D0A07"))
            case .philosophers:       return (Color(hex: "121224"), Color(hex: "07070D"))
            case .entrepreneurs:      return (Color(hex: "121824"), Color(hex: "07090D"))
            case .athletes:           return (Color(hex: "241212"), Color(hex: "0D0707"))
            case .artists:            return (Color(hex: "1B1224"), Color(hex: "0A070D"))
            case .influencers:        return (Color(hex: "122424"), Color(hex: "070D0D"))
            default:                  return (Color(hex: "241E12"), Color(hex: "0D0A07"))
            }
        case .action:
            return (Color(hex: "1A1A1A"), Color(hex: "050505"))
        case .life:
            return (Color(hex: "241218"), Color(hex: "0D070A"))
        }
    }

    // MARK: - SF Symbol Mapping

    private func symbolName(for medium: QuoteMediumCategory) -> String {
        switch medium {
        case .politiciansLeaders:  return "person.badge.key.fill"
        case .philosophers:        return "scroll.fill"
        case .entrepreneurs:       return "briefcase.fill"
        case .athletes:            return "figure.run"
        case .artists:             return "paintpalette.fill"
        case .influencers:         return "play.rectangle.fill"
        case .selfDiscipline:      return "dumbbell.fill"
        case .awakening:           return "bolt.fill"
        case .mindset:             return "eye.fill"
        case .battle:              return "scope"
        case .morning:             return "sunrise.fill"
        case .loveRelationships:   return "heart.fill"
        case .gratitudeHappiness:  return "sun.max.fill"
        case .adversity:           return "cloud.bolt.fill"
        case .timeMortality:       return "hourglass"
        case .selfAcceptance:      return "person.fill.checkmark"
        }
    }
}

// MARK: - Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
