import UIKit
import SwiftUI
import Social

/// SNSシェア機能マネージャー
/// - 画像生成
/// - 釣り場理論準拠のシェア文言
/// - UIActivityViewControllerでシェア
final class ShareManager {
    // MARK: - Singleton

    static let shared = ShareManager()

    private init() {}

    // MARK: - Share Methods

    /// 名言をシェア（UIActivityViewController使用）
    /// - Parameters:
    ///   - quote: 名言オブジェクト
    ///   - viewController: 呼び出し元のViewController
    ///   - format: シェア画像フォーマット（Stories or Square）
    func shareQuote(
        quote: Quote,
        from viewController: UIViewController,
        format: ShareImageFormat = .stories
    ) {
        // 1. 画像生成
        guard let shareImage = generateShareImage(quote: quote, format: format) else {
            print("⚠️ シェア画像の生成に失敗しました")
            return
        }

        // 2. シェア文言（釣り場理論準拠）
        let shareText = getShareText(quote: quote)

        // 3. UIActivityViewController
        let activityItems: [Any] = [shareImage, shareText]

        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // iPadでクラッシュしないように設定
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        viewController.present(activityViewController, animated: true)
    }

    // MARK: - SwiftUI用のシェア

    /// SwiftUI用のシェアアイテム生成
    func getShareItems(quote: Quote, format: ShareImageFormat = .stories) -> [Any] {
        var items: [Any] = []

        if let image = generateShareImage(quote: quote, format: format) {
            items.append(image)
        }

        items.append(getShareText(quote: quote))

        return items
    }

    // MARK: - Private Methods

    /// シェア画像を生成
    private func generateShareImage(quote: Quote, format: ShareImageFormat) -> UIImage? {
        let backgroundImage = loadBackgroundImage(for: quote)

        switch format {
        case .stories:
            return ImageGenerator.generateInstagramStoriesImage(
                quote: quote,
                backgroundImage: backgroundImage
            )
        case .square:
            return ImageGenerator.generateShareImage(
                quote: quote,
                backgroundImage: backgroundImage
            )
        }
    }

    /// 背景画像を読み込み
    private func loadBackgroundImage(for quote: Quote) -> UIImage? {
        // 背景画像の取得を試みる
        if let image = UIImage(named: quote.backgroundImage) {
            return image
        }

        // フォールバック: デフォルト背景
        return UIImage(named: "majestic_peak")
    }

    /// シェア文言を取得（釣り場理論準拠）
    private func getShareText(quote: Quote) -> String {
        let hooks = [
            "これ読んで朝から\(quote.category.displayText.dropFirst(2))する気になった。読まない方がいいかも。",
            "毎朝これ読んでるけど、今日のはちょっとヤバかった。",
            "この名言、シンプルだけど強烈。",
            "今日の名言、保存する価値ある。マジで。",
            "これ、朝イチで読むとマジで変わる。",
            "今日の名言、読んだ瞬間に鳥肌立った。"
        ]

        return hooks.randomElement() ?? "今日の名言をシェアします。"
    }
}

// MARK: - Share Image Format

enum ShareImageFormat {
    case stories    // Instagram Stories用（1080x1920）
    case square     // 汎用シェア用（1080x1080）
}

// MARK: - SwiftUI Integration

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - ShareQuoteView (SwiftUI用の完全なシェアビュー)

struct ShareQuoteView: View {
    let quote: Quote
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var shareFormat: ShareImageFormat = .stories

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    // プレビュー
                    sharePreview

                    Spacer()

                    // フォーマット選択
                    formatSelector

                    // シェアボタン
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)

                            Text("シェアする")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("シェア")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: ShareManager.shared.getShareItems(quote: quote, format: shareFormat))
            }
        }
    }

    // MARK: - Subviews

    private var sharePreview: some View {
        VStack(spacing: 16) {
            Text("プレビュー")
                .font(.caption)
                .foregroundColor(.gray)

            // プレビュー画像（簡易版）
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: shareFormat == .stories ? 533 : 300)

                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(accentGold)

                    Text(quote.quoteJa)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(5)

                    Text("— \(quote.author)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(24)
                .frame(width: 280)
            }
        }
    }

    private var formatSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("フォーマット")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                FormatButton(
                    title: "Stories",
                    subtitle: "9:16",
                    isSelected: shareFormat == .stories
                ) {
                    shareFormat = .stories
                }

                FormatButton(
                    title: "Square",
                    subtitle: "1:1",
                    isSelected: shareFormat == .square
                ) {
                    shareFormat = .square
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Format Button

struct FormatButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? accentGold : .white)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentGold : Color.white.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ShareQuoteView(
        quote: Quote(
            quoteJa: "考えるな、動け。\nお前が悩んでいる間に、\nライバルはもう行動している。",
            author: "Unknown",
            authorDescription: "不明",
            category: .awakening,
            punchline: "考えるな、動け。",
            backgroundImage: "bg_fire_01",
            pushNotificationHook: "今日の名言、読んだ瞬間に鳥肌立った..."
        )
    )
}
