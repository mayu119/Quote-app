import SwiftUI
import SwiftData

struct WeeklyShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSettings: UserSettings
    @State private var summary: QuoteDataService.WeeklyShelfSummary?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if let summary, summary.favoriteCount > 0 {
                    ScrollView {
                        VStack(alignment: .leading, spacing: WFM.Space.l) {
                            Text("私の棚")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                            Text("今週は「\(summary.topCategory?.displayTitleJa ?? "言葉")」の言葉を\(summary.favoriteCount)枚集めました。")
                                .font(.body).foregroundStyle(WFM.ColorToken.textSub)

                            if userSettings.isPremiumUser {
                                ForEach(summary.quotes, id: \.id) { quote in
                                    Text(quote.punchline)
                                        .font(.title3.weight(.medium))
                                        .padding(WFM.Space.m)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(WFM.ColorToken.sheetBase, in: RoundedRectangle(cornerRadius: WFM.Radius.m, style: .continuous))
                                }
                            } else {
                                VStack(spacing: WFM.Space.m) {
                                    Text("棚の中は、プレミアムで開けます")
                                        .font(.headline)
                                    Button("棚を開く") { showPaywall = true }
                                        .buttonStyle(.borderedProminent)
                                        .tint(WFM.ColorToken.accentRose)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(WFM.Space.l)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: WFM.Radius.l, style: .continuous))
                            }
                        }
                        .padding(WFM.Space.l)
                    }
                } else {
                    ContentUnavailableView("今週の棚はまだ空です", systemImage: "bookmark", description: Text("それも、そういう週です。"))
                }
            }
            .background(WFM.ColorToken.pageBase)
            .navigationTitle("今週の棚")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
            .task { summary = try? QuoteDataService(modelContext: modelContext).getWeeklyShelfSummary() }
            .fullScreenCover(isPresented: $showPaywall) { PremiumView(context: .weeklyShelf).environmentObject(userSettings) }
        }
    }
}
