import SwiftUI
import SwiftData

struct MonthlyReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSettings: UserSettings
    @State private var summary: QuoteDataService.MonthlyShelfSummary?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if let summary, summary.favoriteCount > 0 {
                    ScrollView {
                        VStack(alignment: .leading, spacing: WFM.Space.l) {
                            Text("先月の言葉")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                            Text("\(summary.favoriteCount)枚の言葉を棚に置きました。")
                                .font(.body).foregroundStyle(WFM.ColorToken.textSub)
                            Text("「\(summary.topCategory?.displayTitleJa ?? "言葉")」に向き合った月でした。")
                                .font(.title3.weight(.medium))
                            if userSettings.isPremiumUser {
                                Text("先月のベスト3")
                                    .font(.headline)
                                ForEach(summary.bestQuotes, id: \.id) { quote in
                                    Text(quote.punchline)
                                        .padding(WFM.Space.m)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(WFM.ColorToken.sheetBase, in: RoundedRectangle(cornerRadius: WFM.Radius.m, style: .continuous))
                                }
                                Text("来月も、今のあなたに合う言葉を選びます。")
                                    .font(.body).foregroundStyle(WFM.ColorToken.textSub)
                            } else {
                                Button("レポートを開く") { showPaywall = true }
                                    .buttonStyle(.borderedProminent).tint(WFM.ColorToken.accentRose)
                            }
                        }.padding(WFM.Space.l)
                    }
                } else {
                    ContentUnavailableView("先月のレポートはまだありません", systemImage: "calendar", description: Text("棚に置いた言葉から、次の月にレポートを作ります。"))
                }
            }
            .background(WFM.ColorToken.pageBase)
            .navigationTitle("月次レポート")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
            .task { summary = try? QuoteDataService(modelContext: modelContext).getMonthlyShelfSummary() }
            .fullScreenCover(isPresented: $showPaywall) { PremiumView(context: .weeklyShelf).environmentObject(userSettings) }
        }
        .preferredColorScheme(.dark)
    }
}
