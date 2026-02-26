import UIKit
import SwiftUI

/// 名言シェア用の画像生成ユーティリティ
/// - Instagram Stories対応（1080x1920）
/// - 高品質背景 + 名言テキスト + ロゴ透かし
final class ImageGenerator {
    // MARK: - Instagram Stories用画像生成

    /// Instagram Stories用の画像を生成
    /// - Parameters:
    ///   - quote: 名言オブジェクト
    ///   - backgroundImage: 背景画像（オプショナル）
    /// - Returns: 生成された画像
    static func generateInstagramStoriesImage(
        quote: Quote,
        backgroundImage: UIImage? = nil
    ) -> UIImage? {
        // Instagram Storiesのサイズ: 1080 x 1920
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 1. 背景層
            drawBackground(in: rect, context: context, backgroundImage: backgroundImage)

            // 2. ダークグラデーション
            drawDarkGradient(in: rect, context: context)

            // 3. 名言テキスト
            drawQuoteText(quote: quote, in: rect, context: context)

            // 4. ロゴ透かし
            drawLogoWatermark(in: rect, context: context)
        }

        return image
    }

    // MARK: - 汎用シェア画像生成

    /// 汎用シェア用の画像を生成（正方形）
    /// - Parameters:
    ///   - quote: 名言オブジェクト
    ///   - backgroundImage: 背景画像（オプショナル）
    /// - Returns: 生成された画像
    static func generateShareImage(
        quote: Quote,
        backgroundImage: UIImage? = nil
    ) -> UIImage? {
        // 正方形: 1080 x 1080
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 1. 背景層
            drawBackground(in: rect, context: context, backgroundImage: backgroundImage)

            // 2. ダークグラデーション
            drawDarkGradient(in: rect, context: context)

            // 3. 名言テキスト（正方形用）
            drawQuoteTextSquare(quote: quote, in: rect, context: context)

            // 4. ロゴ透かし
            drawLogoWatermark(in: rect, context: context)
        }

        return image
    }

    // MARK: - Drawing Methods

    /// 背景を描画
    private static func drawBackground(
        in rect: CGRect,
        context: UIGraphicsImageRendererContext,
        backgroundImage: UIImage?
    ) {
        if let bgImage = backgroundImage {
            let imageRatio = bgImage.size.width / bgImage.size.height
            let rectRatio = rect.width / rect.height
            
            var drawRect = rect
            if imageRatio > rectRatio {
                // 横に長い（またはrectが縦長）
                let newWidth = rect.height * imageRatio
                drawRect.origin.x = (rect.width - newWidth) / 2
                drawRect.size.width = newWidth
            } else {
                // 縦に長い（またはrectが横長）
                let newHeight = rect.width / imageRatio
                drawRect.origin.y = (rect.height - newHeight) / 2
                drawRect.size.height = newHeight
            }
            
            // はみ出し部分をクリップ（切り抜き）して中央をアスペクトフィルで描画
            context.cgContext.saveGState()
            context.cgContext.clip(to: rect)
            bgImage.draw(in: drawRect)
            context.cgContext.restoreGState()
        } else {
            // フォールバック: グラデーション背景
            let colors = [
                UIColor.black.cgColor,
                UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).cgColor
            ]

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: rect.width, y: rect.height),
                options: []
            )
        }
    }

    /// ダークグラデーションを描画
    private static func drawDarkGradient(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let colors = [
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0.9).cgColor
        ]

        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.0, 0.5, 1.0]
        )!

        context.cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: rect.height),
            options: []
        )
    }

    /// 名言テキストを描画（Instagram Stories用）
    private static func drawQuoteText(quote: Quote, in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let padding: CGFloat = 80
        let textRect = rect.insetBy(dx: padding, dy: padding)

        // アクセントゴールド
        let accentGold = UIColor(red: 0.85, green: 0.65, blue: 0.2, alpha: 1.0)

        // 1. カテゴリバッジ
        let categoryText = quote.category.displayText
        let categoryFont = UIFont.systemFont(ofSize: 32, weight: .bold)
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: categoryFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]

        let categorySize = categoryText.size(withAttributes: categoryAttributes)
        let categoryBadgeRect = CGRect(
            x: padding,
            y: padding + 100,
            width: categorySize.width + 40,
            height: categorySize.height + 20
        )

        let categoryBadgePath = UIBezierPath(roundedRect: categoryBadgeRect, cornerRadius: categorySize.height / 2)
        UIColor.white.withAlphaComponent(0.2).setFill()
        categoryBadgePath.fill()

        categoryText.draw(
            at: CGPoint(x: categoryBadgeRect.minX + 20, y: categoryBadgeRect.minY + 10),
            withAttributes: categoryAttributes
        )

        // 2. 引用符アイコン
        let quoteIconY = categoryBadgeRect.maxY + 120
        let quoteIconText = "\""
        let quoteIconFont = UIFont.systemFont(ofSize: 120, weight: .black)
        let quoteIconAttributes: [NSAttributedString.Key: Any] = [
            .font: quoteIconFont,
            .foregroundColor: accentGold
        ]

        quoteIconText.draw(
            at: CGPoint(x: padding, y: quoteIconY),
            withAttributes: quoteIconAttributes
        )

        // 3. 名言本文
        let quoteY = quoteIconY + 160
        let quoteFont = UIFont.systemFont(ofSize: 72, weight: .heavy)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 20

        let quoteAttributes: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let quoteTextRect = CGRect(
            x: padding,
            y: quoteY,
            width: rect.width - padding * 2,
            height: 900
        )

        quote.quoteJa.draw(in: quoteTextRect, withAttributes: quoteAttributes)

        // 4. 偉人名
        let authorY = rect.height - padding - 200
        let authorFont = UIFont.systemFont(ofSize: 40, weight: .semibold)
        let authorAttributes: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]

        let authorText = "— \(quote.author.uppercased())"
        authorText.draw(
            at: CGPoint(x: padding, y: authorY),
            withAttributes: authorAttributes
        )
    }

    /// 名言テキストを描画（正方形用）
    private static func drawQuoteTextSquare(quote: Quote, in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let padding: CGFloat = 60
        let accentGold = UIColor(red: 0.85, green: 0.65, blue: 0.2, alpha: 1.0)

        // 1. 引用符
        let quoteIconText = "\""
        let quoteIconFont = UIFont.systemFont(ofSize: 80, weight: .black)
        let quoteIconAttributes: [NSAttributedString.Key: Any] = [
            .font: quoteIconFont,
            .foregroundColor: accentGold
        ]

        quoteIconText.draw(
            at: CGPoint(x: padding, y: padding + 200),
            withAttributes: quoteIconAttributes
        )

        // 2. 名言本文
        let quoteY = padding + 320
        let quoteFont = UIFont.systemFont(ofSize: 54, weight: .heavy)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 16
        paragraphStyle.alignment = .left

        let quoteAttributes: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let quoteTextRect = CGRect(
            x: padding,
            y: quoteY,
            width: rect.width - padding * 2,
            height: 600
        )

        quote.quoteJa.draw(in: quoteTextRect, withAttributes: quoteAttributes)

        // 3. 偉人名
        let authorY = rect.height - padding - 120
        let authorFont = UIFont.systemFont(ofSize: 32, weight: .semibold)
        let authorAttributes: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]

        let authorText = "— \(quote.author.uppercased())"
        authorText.draw(
            at: CGPoint(x: padding, y: authorY),
            withAttributes: authorAttributes
        )
    }

    /// ロゴ透かしを描画
    private static func drawLogoWatermark(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let padding: CGFloat = 60
        let logoText = "QUOTE APP" // 実際のアプリ名に置き換える
        let logoFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.3)
        ]

        let logoSize = logoText.size(withAttributes: logoAttributes)
        let logoX = rect.width - padding - logoSize.width
        let logoY = rect.height - padding - logoSize.height - 40

        logoText.draw(
            at: CGPoint(x: logoX, y: logoY),
            withAttributes: logoAttributes
        )
    }
}
