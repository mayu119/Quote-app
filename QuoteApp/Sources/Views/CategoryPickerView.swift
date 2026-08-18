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

    private let pageBackground = WFM.ColorToken.nightBase
    private let sheetBackground = WFM.ColorToken.nightRaised
    private let primaryText = WFM.ColorToken.nightTextPrimary
    private let secondaryText = WFM.ColorToken.nightTextSub
    private let accentRose = WFM.ColorToken.nightRose
    private let accentLavender = Color(hex: "8D90A2")
    private let accentSage = Color(hex: "9EB59B")
    private let accentSky = Color(hex: "9FC8D8")
    private let borderColor = Color.white.opacity(0.12)
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [pageBackground, WFM.ColorToken.nightHigh, pageBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                VStack(spacing: 0) {
                    header
                        .zIndex(10)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 44) {
                            allRandomCard
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.1), value: appear)

                            ForEach(Array(QuoteLargeCategory.allCases.enumerated()), id: \.element) { index, large in
                                largeCategorySection(large: large)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 30)
                                    .animation(.easeOut(duration: 0.7).delay(Double(index) * 0.1 + 0.2), value: appear)
                            }
                        }
                        .padding(.bottom, 72)
                    }
                }
                .background(sheetBackground)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 28, x: 0, y: 12)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
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
                    Text("キャンセル")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(primaryText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                }

                Spacer()
                Color.clear.frame(width: 84, height: 40)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("カテゴリー")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(primaryText)

                Text("今の気分に合わせて、読みたい言葉を選べます。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 18)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
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
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? accentLavender : Color.white.opacity(0.10))
                        .frame(width: 44, height: 44)
                    Image(systemName: "shuffle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? WFM.ColorToken.nightInk : primaryText.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("独自のミックスを作る")
                        .font(.system(size: 18, weight: .bold))
                    Text("その日の気分に合わせて幅広く表示")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(secondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(accentLavender)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                }
            }
            .foregroundColor(primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(isSelected ? accentLavender.opacity(0.22) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? accentLavender.opacity(0.8) : borderColor, lineWidth: isSelected ? 1.4 : 1)
            )
            .shadow(color: isSelected ? accentLavender.opacity(0.22) : .clear, radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 大カテゴリセクション

    private func largeCategorySection(large: QuoteLargeCategory) -> some View {
        let mediums = QuoteMediumCategory.allCases.filter { $0.largeCategory == large }
        let isLargeSelected = selectedLargeCategory == large && selectedMediumCategory == nil
        let isLocked = !userSettings.isPremiumUser

        return VStack(alignment: .leading, spacing: 24) {
            Button(action: {
                if isLocked {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    // Analytics: ロックカテゴリタップ
                    AnalyticsService.shared.logCategoryLockedTap(categoryMedium: nil, categoryLarge: large.rawValue)
                    onPremiumRequired()
                } else {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSelect(nil, large)
                    dismiss()
                }
            }) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(large.displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(primaryText)

                        Text(sectionSubtitle(for: large))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryText)
                    }

                    Spacer()

                    if isLargeSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(accentRose)
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText.opacity(0.7))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(secondaryText.opacity(0.8))
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(mediums, id: \.self) { medium in
                    mediumCategoryCard(medium: medium)
                }
            }
            .padding(.horizontal, 20)
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
                // Analytics: ロックカテゴリタップ
                AnalyticsService.shared.logCategoryLockedTap(categoryMedium: medium.rawValue, categoryLarge: medium.largeCategory.rawValue)
                onPremiumRequired()
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSelect(medium, nil)
                dismiss()
            }
        }) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [cardColorTop(for: medium).opacity(0.10), cardColorBottom(for: medium).opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 118)
                    .frame(maxHeight: .infinity, alignment: .top)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardGradient(for: medium))
                    .frame(height: 118)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .opacity(0.22)

                Image(systemName: symbolName(for: medium))
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(iconColor(for: medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 22)
                    .padding(.trailing, 18)

                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 56, height: 56)
                    .blur(radius: 10)
                    .offset(x: 10, y: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                VStack {
                    HStack {
                        if isSelected {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(accentRose)
                        }
                        
                        Spacer()
                        
                        if isFreeToday {
                            Text("FREE")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(WFM.ColorToken.nightInk)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(WFM.ColorToken.nightRoseSoft)
                                .clipShape(Capsule())
                        } else if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(secondaryText.opacity(0.65))
                        }
                    }
                    Spacer()
                }
                .padding(14)

                VStack(alignment: .leading, spacing: 4) {
                    Text(medium.displayTitleJa)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryText)
                        .lineLimit(2)
                    
                    Text(cardCaption(for: medium))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                        .lineLimit(2)
                }
                .padding(14)
                .padding(.top, 124)

                if isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accentRose, lineWidth: 2)
                        .shadow(color: accentRose.opacity(0.3), radius: 12)
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }
                
                if isLocked {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.38))
                }
            }
            .frame(height: 210)
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 10)
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
        case .selfGrowth:
            switch medium {
            case .selfLove:      return (Color(hex: "F7D9D4"), Color(hex: "F1C6C9"))
            case .positive:      return (Color(hex: "D8E8B6"), Color(hex: "BFD799"))
            case .courage:       return (Color(hex: "D5CDEC"), Color(hex: "C2B7E5"))
            case .innerStrength: return (Color(hex: "DCC8C1"), Color(hex: "D2B2A9"))
            case .affirmation:   return (Color(hex: "CFE3EB"), Color(hex: "B8D4DE"))
            default:             return (Color(hex: "F7D9D4"), Color(hex: "F1C6C9"))
            }
        case .relationships:
            switch medium {
            case .loveCrush:     return (Color(hex: "F7C7D0"), Color(hex: "F2AEBE"))
            case .familyLove:    return (Color(hex: "D9E3C8"), Color(hex: "C5D4AE"))
            case .forMyChild:    return (Color(hex: "F3DCC6"), Color(hex: "EBCDB0"))
            case .relationships: return (Color(hex: "C8DDE6"), Color(hex: "B1CBD6"))
            default:             return (Color(hex: "F7C7D0"), Color(hex: "F2AEBE"))
            }
        case .reset:
            return (Color(hex: "D6D1E8"), Color(hex: "BFB8DA"))
        }
    }

    // MARK: - SF Symbol Mapping

    private func symbolName(for medium: QuoteMediumCategory) -> String {
        switch medium {
        case .selfLove:      return "heart.circle.fill"
        case .positive:      return "sun.max.fill"
        case .courage:       return "sparkles"
        case .innerStrength: return "mountain.2.fill"
        case .loveCrush:     return "heart.fill"
        case .familyLove:    return "house.fill"
        case .forMyChild:    return "figure.and.child.holdinghands"
        case .relationships: return "person.2.fill"
        case .wantToQuit:    return "moon.stars.fill"
        case .affirmation:   return "quote.bubble.fill"
        }
    }

    private func sectionSubtitle(for large: QuoteLargeCategory) -> String {
        switch large {
        case .selfGrowth:
            return "自分を整えて、自信をやさしく育てる言葉"
        case .relationships:
            return "恋愛や家族、人とのつながりに寄り添う言葉"
        case .reset:
            return "疲れた心をゆっくり立て直すための言葉"
        }
    }

    private func cardCaption(for medium: QuoteMediumCategory) -> String {
        switch medium {
        case .selfLove: return "そのままの自分を受け入れる"
        case .positive: return "気分を明るく整える"
        case .courage: return "一歩を踏み出したい時に"
        case .innerStrength: return "しなやかな芯を育てる"
        case .loveCrush: return "恋の始まりに寄り添う"
        case .familyLove: return "家族への想いをあたためる"
        case .forMyChild: return "大切な人へ向けるやさしさ"
        case .relationships: return "人間関係の距離感を整える"
        case .wantToQuit: return "疲れた日に心を立て直す"
        case .affirmation: return "一人称の言葉で自分を整える"
        }
    }

    private func cardColorTop(for medium: QuoteMediumCategory) -> Color {
        switch medium {
        case .selfLove: return Color(hex: "FFF5F2")
        case .positive: return Color(hex: "F6F9EA")
        case .courage: return Color(hex: "F4F0FC")
        case .innerStrength: return Color(hex: "F7F0EC")
        case .loveCrush: return Color(hex: "FFF1F4")
        case .familyLove: return Color(hex: "F4F7EE")
        case .forMyChild: return Color(hex: "FCF4EC")
        case .relationships: return Color(hex: "F2F8FA")
        case .wantToQuit: return Color(hex: "F3F0FA")
        case .affirmation: return Color(hex: "F1F9FB")
        }
    }

    private func cardColorBottom(for medium: QuoteMediumCategory) -> Color {
        switch medium {
        case .selfLove: return Color(hex: "F8D9D6")
        case .positive: return Color(hex: "D8E8B6")
        case .courage: return Color(hex: "D8CFF0")
        case .innerStrength: return Color(hex: "DDC8C0")
        case .loveCrush: return Color(hex: "F6C7D2")
        case .familyLove: return Color(hex: "D7E2C3")
        case .forMyChild: return Color(hex: "F1DDC8")
        case .relationships: return Color(hex: "CFE3EA")
        case .wantToQuit: return Color(hex: "D8D2EA")
        case .affirmation: return Color(hex: "CAE4EB")
        }
    }

    private func iconColor(for medium: QuoteMediumCategory) -> Color {
        switch medium {
        case .selfLove, .loveCrush: return accentRose
        case .positive, .familyLove: return accentSage
        case .courage, .wantToQuit: return accentLavender
        case .innerStrength, .forMyChild: return Color(hex: "C78F83")
        case .relationships, .affirmation: return accentSky
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
