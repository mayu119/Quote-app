import SwiftUI
import UIKit

/// 名言カードとシェア画像で共用する縦書き表示。
struct VerticalTextView: View {
    var text: String
    var fontName: String = "HiraMinProN-W6"
    var fontSize: CGFloat
    var lineSpacing: CGFloat
    var textColor: Color = .white
    var scalesWithDynamicType: Bool = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let _ = dynamicTypeSize
        let effectiveFontSize = scalesWithDynamicType
            ? min(UIFontMetrics(forTextStyle: .title2).scaledValue(for: fontSize), fontSize * 1.25)
            : fontSize
        HStack(alignment: .top, spacing: lineSpacing) {
            let lines = text.split(separator: "\n").map(String.init)
            ForEach(Array(lines.reversed().enumerated()), id: \.offset) { _, line in
                VStack(spacing: 0) {
                    ForEach(Array(Array(line).enumerated()), id: \.offset) { _, character in
                        Text(String(character))
                            .font(.custom(fontName, fixedSize: effectiveFontSize))
                            .foregroundStyle(textColor)
                            .rotationEffect(needsRotation(character) ? .degrees(90) : .zero)
                            .offset(characterOffset(character, fontSize: effectiveFontSize))
                            .frame(height: effectiveFontSize * 1.1)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text.replacingOccurrences(of: "\n", with: ""))
    }

    private func needsRotation(_ character: Character) -> Bool {
        let characters: Set<Character> = ["ー", "-", "~", "〜", "(", ")", "「", "」", "『", "』", "（", "）", "＜", "＞", "[", "]"]
        return characters.contains(character)
    }

    private func characterOffset(_ character: Character, fontSize: CGFloat) -> CGSize {
        let punctuation: Set<Character> = ["。", "、", ".", ","]
        if punctuation.contains(character) {
            return CGSize(width: fontSize * 0.6, height: -fontSize * 0.6)
        }
        let smallKana: Set<Character> = ["ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "っ", "ゃ", "ゅ", "ょ", "ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ"]
        if smallKana.contains(character) {
            return CGSize(width: fontSize * 0.15, height: -fontSize * 0.15)
        }
        return .zero
    }
}
