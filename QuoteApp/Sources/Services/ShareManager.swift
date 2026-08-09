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
        format: ShareImageFormat = .stories,
        isVertical: Bool = false
    ) {
        // 1. 画像生成と文言取得 (SwiftUIベースのViewから取得)
        let activityItems = getShareItems(
            quote: quote,
            quoteIndex: quoteIndex,
            backgroundName: backgroundName,
            format: format,
            isVertical: isVertical
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
        format: ShareImageFormat,
        isVertical: Bool = false
    ) -> Bool {
        // 1. レンダリングして画像を取得
        let shareView = QuoteShareSnapshotView(
            quote: quote,
            quoteIndex: quoteIndex,
            backgroundName: backgroundName,
            format: format,
            isVertical: isVertical
        )
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 1.0
        guard let stickerImage = renderer.uiImage else { return false }
        
        // 2. 背景に使用する画像（縦長で全画面を覆うもの）
        let bgImage = UIImage(named: backgroundName) ?? UIImage()

        // 3. Instagram StoriesのURL Schemeを構築
        guard let url = URL(string: "instagram-stories://share?source_application=\(Config.instagramSourceApplicationID)") else { return false }
        
        if UIApplication.shared.canOpenURL(url) {
            // Instagramアプリがインストールされている場合
            
            var pasteboardItems: [String: Any] = [:]
            
            // Stories format, the image is 1080x1920, just use it as background
            pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = stickerImage.pngData()
            
            let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)]
            UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            // Analytics: Instagram Storiesシェア
            AnalyticsService.shared.logShareInstagramStories(quoteId: quote.id, author: quote.author, success: true)
            return true
        } else {
            print("Instagram app is not installed.")
            AnalyticsService.shared.logShareInstagramStories(quoteId: quote.id, author: quote.author, success: false)
            return false
        }
    }

// MARK: - SwiftUI用のシェア

    /// SwiftUI用のシェアアイテム生成 (MainActor)
    @MainActor
    func getShareItems(
        quote: Quote,
        quoteIndex: Int,
        backgroundName: String,
        format: ShareImageFormat = .stories,
        isVertical: Bool = false
    ) -> [Any] {
        var items: [Any] = []

        let shareView = QuoteShareSnapshotView(
            quote: quote,
            quoteIndex: quoteIndex,
            backgroundName: backgroundName,
            format: format,
            isVertical: isVertical
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

    @MainActor
    func getShelfShareItems(
        quotes: [Quote],
        title: String,
        subtitle: String? = nil
    ) -> [Any] {
        guard !quotes.isEmpty else {
            return ["今の私の言葉の棚をシェアします。"]
        }

        var items: [Any] = []
        let shareView = ShelfShareSnapshotView(
            quotes: quotes,
            title: title,
            subtitle: subtitle
        )

        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 1.0

        if let image = renderer.uiImage {
            items.append(image)
        } else {
            print("⚠️ 棚シェア画像のレンダリングに失敗しました")
        }

        let summary = quotes.map(\.punchline).joined(separator: " / ")
        items.append("今の私の言葉の棚。\n\(summary)")
        return items
    }

    // MARK: - Private Methods

    /// シェア文言を取得（釣り場理論準拠）
    private func getShareText(quote: Quote) -> String {
        let hooks = [
            "今日ひらいたこの言葉、思っていた以上に心に残った。",
            "気持ちを整えたい日に、こういう一節があると助かる。",
            "ことだまみたいに、静かだけどちゃんと残る言葉だった。",
            "保存して、また自分の棚から読み返したい言葉だった。",
            "今日の自分に、ちょうどいい温度の言葉が届いた。",
            "少し空気が澄むような一節だった。"
        ]

        return hooks.randomElement() ?? "今日の言葉をシェアします。"
    }
}

// MARK: - Share Image Format

enum ShareImageFormat {
    case stories    // Instagram Stories用（1080x1920）
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
    var isVertical: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
            
            // 1. Background Image
            Image(backgroundName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 1080, height: 1920)
                .blur(radius: 4)
                .opacity(0.85)
                .clipped()
            
            // 2. Chiaroscuro Gradient
            RadialGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6), .black.opacity(1.0)]),
                center: .center,
                startRadius: 150,
                endRadius: 1920 * 0.8
            )
            
            // 3. Bottom Gradient
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 700)
            }
            
            // 4. Quote Index Watermark
            Text(String(format: "%02d", quoteIndex))
                .font(.system(size: 500, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.10))
                .offset(x: 200, y: -80)
            
            // 4.5 App Name
            VStack {
                Text("WORDS FOR ME")
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .tracking(24)
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 5)

                Text("Words For Me  •  App Storeで続きも読む")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .tracking(6)
                    .foregroundColor(.white.opacity(0.48))
                    .padding(.top, 12)

                Spacer()
            }
            .padding(.top, 180)
            
            // 5. Content
            if isVertical {
                verticalShareContent
            } else {
                horizontalShareContent
            }
        }
        .frame(width: 1080, height: 1920)
        .ignoresSafeArea(.all)
    }

    private var horizontalShareContent: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 80) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 150, weight: .black))
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: -20, y: 30)
                
                Text(quote.quoteJa)
                    .font(.custom("HiraginoSans-W8", size: 90))
                    .fontWeight(.black)
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(25)
                    .minimumScaleFactor(0.4)
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 5)
                    .fixedSize(horizontal: false, vertical: true)
                
                if quote.hasVisibleAuthorAttribution {
                    HStack(spacing: 30) {
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 80, height: 3)

                        Text(quote.displayAuthor)
                            .font(.system(size: 28, weight: .bold))
                            .tracking(10)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 100)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            Spacer() // Push content slightly up
        }
    }

    private var verticalShareContent: some View {
        let availableTextHeight: CGFloat = 1920 * 0.45
        let baseFontSize: CGFloat = 90.0
        let maxCharsPerLine = max(10, Int(availableTextHeight / (baseFontSize * 1.15)))
            let foldedText = JapaneseLineBreaker.fold(quote.quoteJa, maxPerLine: maxCharsPerLine)
        let maxLineLength = foldedText.components(separatedBy: "\n").map { $0.count }.max() ?? 1
        
        let calcSize = availableTextHeight / CGFloat(maxLineLength) / 1.15
        let dynamicFontSize = min(100.0, max(50.0, calcSize))
        
        return ZStack(alignment: .bottomLeading) {
            
            // 1. 名言本体
            Group {
                VerticalTextView(
                    text: foldedText,
                    fontName: "HiraMinProN-W6",
                    fontSize: dynamicFontSize,
                    lineSpacing: 40,
                    textColor: .white
                )
                .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            // 2. 著者名（左下寄せ・完全に独立したZStack配置）
            if quote.hasVisibleAuthorAttribution {
                HStack(alignment: .bottom, spacing: 30) {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 100)

                    VerticalTextView(
                        text: quote.displayAuthor,
                        fontName: "HiraginoSans-W6",
                        fontSize: 34,
                        lineSpacing: 0,
                        textColor: .white.opacity(0.8)
                    )
                }
                .padding(.leading, 120)
                .padding(.bottom, 350)
            }
        }
        .frame(width: 1080, height: 1920 * 0.75) // 上下にある程度の余白を持たせる
        .frame(width: 1080, height: 1920, alignment: .center) // 画像全体の中心に配置
    }
}

struct ShelfShareSnapshotView: View {
    let quotes: [Quote]
    let title: String
    let subtitle: String?

    private let pageBackground = Color(hex: "F4EEE8")
    private let cardTop = Color(hex: "FFF4F2")
    private let cardBottom = Color(hex: "F3D6D8")
    private let panelFill = Color.white.opacity(0.92)
    private let primaryText = Color(hex: "2F2730")
    private let secondaryText = Color(hex: "7D7280")
    private let accentRose = Color(hex: "D98C96")
    private let accentLavender = Color(hex: "8D90A2")

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [pageBackground, Color(hex: "F9F4F0"), Color(hex: "EFE7F4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 360, height: 360)
                .blur(radius: 30)
                .offset(x: 270, y: -520)

            Circle()
                .fill(accentRose.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 22)
                .offset(x: -280, y: -340)

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WORDS FOR ME")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .tracking(8)
                        .foregroundColor(primaryText.opacity(0.92))

                Text("Words For Me")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .foregroundColor(accentLavender)

                    Text(title)
                        .font(.custom("HiraginoSans-W8", size: 58))
                        .foregroundColor(primaryText)
                        .lineSpacing(10)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(secondaryText)
                    }
                }

                VStack(spacing: 18) {
                    ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                        shelfQuoteCard(quote: quote, index: index + 1)
                    }
                }

                Spacer()

                Text("響いた言葉を、ただ流さずに残していく。")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(secondaryText)
            }
            .padding(.horizontal, 82)
            .padding(.top, 140)
            .padding(.bottom, 120)
        }
        .frame(width: 1080, height: 1920)
        .ignoresSafeArea()
    }

    private func shelfQuoteCard(quote: Quote, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(String(format: "%02d", index))
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(accentRose)

                Spacer()

                Text(quote.category.displayTitleJa)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentLavender)
            }

            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W7", size: 34))
                .foregroundColor(primaryText)
                .lineSpacing(10)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Rectangle()
                    .fill(accentRose.opacity(0.55))
                    .frame(width: 24, height: 2)

                Text(quote.displayAuthor)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                panelFill
                LinearGradient(
                    colors: [cardTop, cardBottom.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.65)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1.2)
        )
        .shadow(color: accentRose.opacity(0.10), radius: 20, x: 0, y: 12)
    }
}
// MARK: - ShareQuoteView (SwiftUI用の完全なシェアビュー)

struct ShareQuoteView: View {
    let quote: Quote
    var isVertical: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false

    private let pageBackground = Color(hex: "F1E9E3")
    private let sheetBackground = Color(hex: "FFFCF8")
    private let primaryText = Color(hex: "2F2730")
    private let secondaryText = Color(hex: "7D7280")
    private let accentRose = Color(hex: "EAA3A1")
    private let accentLavender = Color(hex: "8D90A2")
    private let borderColor = Color(hex: "E8DDD6")
    private let quoteCardTop = Color(hex: "FFF1F4")
    private let quoteCardBottom = Color(hex: "F6C7D2")

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [pageBackground, Color(hex: "F7F1EB"), Color(hex: "EFE5DE")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ヘッダー
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("閉じる")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(primaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("シェア")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentLavender)
                            .tracking(0.8)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(primaryText.opacity(0.7))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(borderColor, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(proxy.safeAreaInsets.top, 16) + 6)
                    .padding(.bottom, 20)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // セクションタイトル
                            VStack(alignment: .leading, spacing: 6) {
                                Text("画像でシェア")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(primaryText)
                                Text("この言葉を画像にして共有します")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryText)
                                    .lineSpacing(3)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                            // プレビューカード
                            sharePreview
                                .padding(.horizontal, 20)

                            // シェアボタン
                            Button(action: { showShareSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("シェアする")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(accentLavender)
                                .clipShape(Capsule())
                                .shadow(color: accentLavender.opacity(0.25), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 20)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ShareManager.shared.getShareItems(
                quote: quote,
                quoteIndex: 1,
                backgroundName: quote.backgroundImage,
                format: .stories,
                isVertical: isVertical
            ))
        }
    }

    // MARK: - Subviews

    private var sharePreview: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.94))

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [quoteCardTop, quoteCardBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)
                .frame(maxHeight: .infinity, alignment: .top)

            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(accentRose.opacity(0.88))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 18)
                .padding(.trailing, 18)

            VStack(alignment: .leading, spacing: 12) {
                Text(quote.quoteJa)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(primaryText)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                if quote.hasVisibleAuthorAttribution {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(accentRose.opacity(0.6))
                            .frame(width: 16, height: 1)
                        Text(quote.displayAuthor)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            .padding(18)
            .padding(.top, 96)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color(hex: "D8C8BF").opacity(0.14), radius: 14, x: 0, y: 8)
    }

}

// MARK: - Preview

#Preview {
    ShareQuoteView(
        quote: Quote(
            quoteJa: "私は今日、自分を小さく扱わない。",
            author: "Original",
            authorKana: "オリジナル",
            authorDescription: "アプリオリジナルのアファメーション",
            category: .affirmation,
            punchline: "私は今日、自分を小さく扱わない。",
            backgroundImage: "sunset",
            pushNotificationHook: "今日の自分を、少しだけ大切にする言葉。"
        )
    )
}
