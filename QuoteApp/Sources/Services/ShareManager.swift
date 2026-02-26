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
    @MainActor
    func shareQuote(
        quote: Quote,
        quoteIndex: Int,
        backgroundName: String,
        from viewController: UIViewController,
        format: ShareImageFormat = .stories
    ) {
        // 1. 画像生成と文言取得 (SwiftUIベースのViewから取得)
        let activityItems = getShareItems(
            quote: quote,
            quoteIndex: quoteIndex,
            backgroundName: backgroundName,
            format: format
        )

        // 2. UIActivityViewController
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

    /// Instagram Storiesに直接シェアする専用メソッド
    @MainActor
    func shareToInstagramStories(
        quote: Quote,
        quoteIndex: Int,
        backgroundName: String,
        format: ShareImageFormat
    ) -> Bool {
        // 1. レンダリングして画像を取得
        let shareView = QuoteShareSnapshotView(
            quote: quote,
            quoteIndex: quoteIndex,
            backgroundName: backgroundName,
            format: format
        )
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 1.0
        guard let stickerImage = renderer.uiImage else { return false }
        
        // 2. 背景に使用する画像（縦長で全画面を覆うもの）
        let bgImage = UIImage(named: backgroundName) ?? UIImage()

        // 3. Instagram StoriesのURL Schemeを構築
        guard let url = URL(string: "instagram-stories://share?source_application=9W24U28U8Q") else { return false } // BundleIDやAppIDを指定（無くても動作することが多いが推奨）
        
        if UIApplication.shared.canOpenURL(url) {
            // Instagramアプリがインストールされている場合
            
            var pasteboardItems: [String: Any] = [:]
            
            // if square mode, we pass the 1080x1080 image as a sticker, and use the original background to fill the screen
            if format == .square {
                pasteboardItems["com.instagram.sharedSticker.stickerImage"] = stickerImage.pngData()
                pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = bgImage.pngData()
            } else {
                // If it's already stories format, the image is 1080x1920, just use it as background
                pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = stickerImage.pngData()
            }
            
            let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)]
            UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        } else {
            print("Instagram app is not installed.")
            return false
        }
    }

// MARK: - SwiftUI用のシェア

    /// SwiftUI用のシェアアイテム生成 (MainActor)
    @MainActor
    func getShareItems(quote: Quote, quoteIndex: Int, backgroundName: String, format: ShareImageFormat = .stories) -> [Any] {
        var items: [Any] = []

        let shareView = QuoteShareSnapshotView(
            quote: quote,
            quoteIndex: quoteIndex,
            backgroundName: backgroundName,
            format: format
        )
        
        let renderer = ImageRenderer(content: shareView)
        // Set scale to 1.0 because our view is explicitly 1080x1080 / 1080x1920 logical points
        renderer.scale = 1.0
        
        if let image = renderer.uiImage {
            items.append(image)
        } else {
            print("⚠️ シェア画像のレンダリングに失敗しました")
        }

        items.append(getShareText(quote: quote))

        return items
    }

    // MARK: - Private Methods

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

// MARK: - QuoteShareSnapshotView

struct QuoteShareSnapshotView: View {
    var quote: Quote
    var quoteIndex: Int
    var backgroundName: String
    var format: ShareImageFormat
    
    var isSquare: Bool {
        format == .square
    }

    var body: some View {
        ZStack {
            Color.black
            
            // 1. Background Image
            Image(backgroundName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: isSquare ? 1080 : 1080, height: isSquare ? 1080 : 1920)
                .blur(radius: 4)
                .opacity(0.85)
                .clipped()
            
            // 2. Chiaroscuro Gradient
            RadialGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6), .black.opacity(1.0)]),
                center: .center,
                startRadius: 150,
                endRadius: (isSquare ? 1080 : 1920) * 0.8
            )
            
            // 3. Bottom Gradient
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: isSquare ? 400 : 700)
            }
            
            // 4. Quote Index Watermark
            Text(String(format: "%02d", quoteIndex))
                .font(.system(size: isSquare ? 450 : 500, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.04))
                .offset(x: isSquare ? 150 : 200, y: isSquare ? -50 : -80)
            
            // 5. Content
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: isSquare ? 60 : 80) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: isSquare ? 120 : 150, weight: .black))
                        .foregroundColor(.white.opacity(0.15))
                        .offset(x: -20, y: 30)
                    
                    Text(quote.quoteJa)
                        .font(.custom("HiraginoSans-W8", size: isSquare ? 75 : 90))
                        .fontWeight(.black)
                        .foregroundColor(.white.opacity(0.95))
                        .lineSpacing(25)
                        .minimumScaleFactor(0.4)
                        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 5)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 30) {
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 80, height: 3)
                        
                        Text(quote.author.uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .tracking(10)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 100)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Spacer() // Push content slightly up
            }
        }
        .frame(width: 1080, height: isSquare ? 1080 : 1920)
        .ignoresSafeArea(.all)
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
                ShareSheet(items: ShareManager.shared.getShareItems(
                    quote: quote,
                    quoteIndex: 1,
                    backgroundName: quote.backgroundImage,
                    format: shareFormat
                ))
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
