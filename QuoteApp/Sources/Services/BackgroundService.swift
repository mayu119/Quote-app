import Foundation
import SwiftUI
import UIKit

/// 背景設定ファイルの構造
struct BackgroundConfig: Codable {
    let backgrounds: [String]
}

/// 背景画像管理サービス
final class BackgroundService: ObservableObject {
    @Published var currentBackgroundIndex: Int = 0

    // MARK: - Image Cache (P-29)
    private static let imageCache = NSCache<NSString, UIImage>()

    /// キャッシュ付き画像取得（プリフェッチにも使用）
    func cachedImage(named name: String) -> UIImage? {
        let key = name as NSString
        if let cached = Self.imageCache.object(forKey: key) { return cached }
        if let image = UIImage(named: name) {
            Self.imageCache.setObject(image, forKey: key)
            return image
        }
        return nil
    }

    // MARK: - 背景画像リスト

    static let backgrounds: [String] = {
        guard let url = Bundle.main.url(forResource: "backgrounds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(BackgroundConfig.self, from: data) else {
            print("⚠️ Failed to load backgrounds.json, using default backgrounds")
            return ["majestic_peak"]
        }
        return config.backgrounds
    }()

    // MARK: - Public Methods

    func getCurrentBackground() -> String {
        guard currentBackgroundIndex >= 0 && currentBackgroundIndex < Self.backgrounds.count else {
            return Self.backgrounds[0]
        }
        return Self.backgrounds[currentBackgroundIndex]
    }

    // MARK: - Daily Background (連続しないランダム)

    private static let dailyBgDateKey = "dailyBackgroundDate"
    private static let dailyBgNameKey = "dailyBackgroundName"

    /// 無料ユーザー用: 1日1枚の背景をランダムに選択（前日と被らない）
    static func getDailyBackground() -> String {
        let defaults = UserDefaults.standard
        let todayStr = dateString(for: Date())

        // 今日の保存値があればそのまま返す
        if let savedDate = defaults.string(forKey: dailyBgDateKey),
           savedDate == todayStr,
           let savedBg = defaults.string(forKey: dailyBgNameKey) {
            return savedBg
        }

        // 前日の背景を取得して除外リストに
        let previousBg = defaults.string(forKey: dailyBgNameKey)
        var pool = backgrounds
        if let prev = previousBg {
            pool = pool.filter { $0 != prev }
        }

        let newBg = pool.randomElement() ?? backgrounds[0]

        // 保存
        defaults.set(todayStr, forKey: dailyBgDateKey)
        defaults.set(newBg, forKey: dailyBgNameKey)

        return newBg
    }

    private static func dateString(for date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        return f.string(from: date)
    }

    func nextBackground() {
        currentBackgroundIndex = (currentBackgroundIndex + 1) % Self.backgrounds.count
    }

    func previousBackground() {
        currentBackgroundIndex = (currentBackgroundIndex - 1 + Self.backgrounds.count) % Self.backgrounds.count
    }

    func setBackground(index: Int) {
        guard index >= 0 && index < Self.backgrounds.count else { return }
        currentBackgroundIndex = index
    }

    static var backgroundCount: Int { backgrounds.count }
}
