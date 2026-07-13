import SwiftUI
import SwiftData

/// 夜に一度だけ開く、課金導線を持たない言葉の儀式。
struct NightWordView: View {
    let quote: Quote
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    @State private var note = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "17151F"), Color(hex: "292334"), Color(hex: "111015")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: WFM.Space.l) {
                Spacer()
                Text("夜の一枚")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.56))

                Text(quote.quoteJa)
                    .font(.system(size: 27, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(10)

                Text("— \(quote.displayAuthor)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.58))

                Divider().overlay(.white.opacity(0.16))

                Text("今日をひとことで置いていく")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.84))

                TextField("書かなくても大丈夫です", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(WFM.Space.m)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: WFM.Radius.m, style: .continuous))
                    .foregroundStyle(.white)
                    .tint(Color(hex: "EAA3A1"))
                    .accessibilityLabel("今日をひとことで置いていくメモ")

                Button(action: saveAndClose) {
                    Text(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "このまま閉じる" : "言葉と一緒に残す")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "8B8AAE"))
                Spacer()
            }
            .padding(WFM.Space.l)
        }
        .onAppear { AnalyticsService.shared.logNightWordView() }
    }

    private func saveAndClose() {
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty {
            quote.favoriteNote = cleaned
            quote.isFavorited = true
            quote.favoritedAt = quote.favoritedAt ?? Date()
            try? modelContext.save()
            AnalyticsService.shared.logNightNoteSave(quoteId: quote.id)
        }
        onClose()
    }
}
