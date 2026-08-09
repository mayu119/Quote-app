import SwiftUI

/// Words For Me の共通デザイントークン。
/// 旧値対応: PremiumView の `bgDeep/panelBg/textPrimary/textSub/accentGold` をここへ集約。
enum WFM {
    enum ColorToken {
        // The WFM asset folder is organizational only ("Provides Namespace" is off),
        // so the compiled asset names do not include the folder prefix.
        static let pageBase = Color("PageBase")
        static let sheetBase = Color("SheetBase")
        static let textPrimary = Color("TextPrimary")
        static let textSub = Color("TextSub")
        static let accentRose = Color("AccentRose")
        static let accentGold = Color("AccentGold")

        // メインの引用画面は没入感を優先する意図的な固定ダーク。Asset の自動反転対象外。
        static let nightVeil = Color.black.opacity(0.72)
        static let nightScrim = Color.black.opacity(0.42)

        // 夜の世界(処方箋リビール〜ペイウォール〜メイン体験)で共有する固定パレット。
        static let nightBase = Color(hex: "18151F")
        static let nightRaised = Color(hex: "211B2A")
        static let nightHigh = Color(hex: "332A3C")
        static let nightRose = Color(hex: "D99AA3")
        static let nightRoseSoft = Color(hex: "EEC7BE")
        static let nightInk = Color(hex: "241D2B")
        static let nightTextPrimary = Color.white.opacity(0.94)
        static let nightTextSub = Color.white.opacity(0.66)
    }

    enum Radius { static let s: CGFloat = 12; static let m: CGFloat = 18; static let l: CGFloat = 26; static let xl: CGFloat = 34 }
    enum Space { static let xxs: CGFloat = 4; static let xs: CGFloat = 8; static let s: CGFloat = 12; static let m: CGFloat = 16; static let l: CGFloat = 24; static let xl: CGFloat = 32; static let safeTopFallback: CGFloat = 52 }
    enum Typography {
        static func hero() -> Font { .system(.largeTitle, design: .serif, weight: .semibold) }
        static func title() -> Font { .system(.title2, weight: .bold) }
        static func body() -> Font { .system(.body) }
        static func caption() -> Font { .system(.caption, weight: .medium) }
    }
    enum Motion {
        static let quick = Animation.spring(response: 0.34, dampingFraction: 0.82)
        static let smooth = Animation.spring(response: 0.48, dampingFraction: 0.9)
        static let cardFloatDuration: TimeInterval = 3.8
        static let cardShimmerDuration: TimeInterval = 4.6
        static let cardLiftDuration: TimeInterval = 0.18
        static let revealDuration: TimeInterval = 0.92
        static let reducedRevealDuration: TimeInterval = 0.2
    }
}
