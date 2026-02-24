import Foundation
import SwiftUI

/// 背景設定ファイルの構造
struct BackgroundConfig: Codable {
    let backgrounds: [String]
}

/// 背景画像管理サービス
/// - 日替わり背景の提供（無料版）
/// - ユーザー選択背景の管理（プレミアム版）
final class BackgroundService: ObservableObject {
    @Published var currentBackgroundIndex: Int = 0

    // MARK: - 背景画像リスト

    /// 利用可能な背景画像の名前リスト（JSONから読み込み）
    static let backgrounds: [String] = {
        guard let url = Bundle.main.url(forResource: "backgrounds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(BackgroundConfig.self, from: data) else {
            print("⚠️ Failed to load backgrounds.json, using default backgrounds")
            return ["majestic_peak"] // フォールバック
        }
        return config.backgrounds
    }()

    // MARK: - Public Methods

    /// 現在の背景画像名を取得
    func getCurrentBackground() -> String {
        guard currentBackgroundIndex >= 0 && currentBackgroundIndex < Self.backgrounds.count else {
            return Self.backgrounds[0]
        }
        return Self.backgrounds[currentBackgroundIndex]
    }

    /// 日替わり背景のインデックスを取得（無料版用）
    static func getDailyBackgroundIndex() -> Int {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return dayOfYear % backgrounds.count
    }

    /// 日替わり背景の名前を取得（無料版用）
    static func getDailyBackground() -> String {
        let index = getDailyBackgroundIndex()
        return backgrounds[index]
    }

    /// 次の背景に切り替え（プレミアム版用）
    func nextBackground() {
        currentBackgroundIndex = (currentBackgroundIndex + 1) % Self.backgrounds.count
    }

    /// 前の背景に切り替え（プレミアム版用）
    func previousBackground() {
        currentBackgroundIndex = (currentBackgroundIndex - 1 + Self.backgrounds.count) % Self.backgrounds.count
    }

    /// 背景を指定のインデックスに設定
    func setBackground(index: Int) {
        guard index >= 0 && index < Self.backgrounds.count else { return }
        currentBackgroundIndex = index
    }

    /// 背景の総数を取得
    static var backgroundCount: Int {
        return backgrounds.count
    }
}
