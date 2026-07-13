import SwiftUI
import SwiftData

struct GiftComposeView: View {
    let quotes: [Quote]

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = GiftService.shared
    @State private var selectedID: String
    @State private var note = ""
    @State private var shareURL: URL?
    @State private var errorMessage: String?

    init(quotes: [Quote]) {
        self.quotes = quotes
        _selectedID = State(initialValue: quotes.first?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("贈る言葉") {
                    Picker("言葉", selection: $selectedID) {
                        ForEach(quotes, id: \.id) { quote in
                            Text(String(quote.quoteJa.prefix(28))).tag(quote.id)
                        }
                    }
                    Text(selectedQuote?.quoteJa ?? "棚に置いた言葉を選んでください")
                        .font(.headline)
                        .accessibilityLabel("贈る言葉、\(selectedQuote?.quoteJa ?? "未選択")")
                }

                Section("ひとこと（任意）") {
                    TextField("今のあなたに、置いておきたい言葉です。", text: $note, axis: .vertical)
                        .lineLimit(3...4)
                    Text("\(note.count)/60")
                        .font(.caption)
                        .foregroundStyle(note.count > 60 ? .red : .secondary)
                }

                Section {
                    if let product = service.product {
                        Button("言葉のお守りを \(product.displayPrice) で贈る") { purchase() }
                            .disabled(selectedQuote == nil || note.count > 60 || service.isWorking)
                    } else {
                        ProgressView("商品情報を確認中")
                    }
                } footer: {
                    Text("受け取る方は、購入せず無料で言葉を開いて棚に置けます。")
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("言葉のお守り")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
            .task { await service.loadProduct() }
            .sheet(item: $shareURL) { url in
                GiftShareSheet(url: url)
            }
        }
    }

    private var selectedQuote: Quote? { quotes.first { $0.id == selectedID } }

    private func purchase() {
        guard let selectedQuote else { return }
        errorMessage = nil
        Task {
            do { shareURL = try await service.purchaseAndIssue(quote: selectedQuote, senderNote: note) }
            catch let error as GiftService.GiftError { errorMessage = error.localizedDescription }
            catch { errorMessage = error.localizedDescription }
        }
    }
}

private struct GiftShareSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gift.fill").font(.system(size: 54)).foregroundStyle(.pink)
                Text("お守りができました").font(.title2.bold())
                ShareLink(item: url, subject: Text("言葉のお守り"), message: Text("大切な人から、言葉のお守りが届いています。")) {
                    Label("リンクを共有", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("発行完了")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完了") { dismiss() } } }
            .onAppear { AnalyticsService.shared.logGift("gift_shared", params: ["channel": "share_sheet_presented"]) }
        }
    }
}

struct GiftReceiveView: View {
    let giftID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = GiftService.shared
    @State private var gift: GiftPublicPayload?
    @State private var errorMessage: String?
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Group {
                if let gift {
                    ScrollView {
                        VStack(spacing: 24) {
                            Text("大切な人から、言葉のお守りが届いています")
                                .font(.headline).multilineTextAlignment(.center)
                            Text(gift.quoteJa).font(.title2.bold()).multilineTextAlignment(.center)
                            Text(gift.author).foregroundStyle(.secondary)
                            if !gift.senderNote.isEmpty { Text(gift.senderNote).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)) }
                            Button(saved ? "棚に置きました" : "棚に置く") { save(gift) }
                                .buttonStyle(.borderedProminent).disabled(saved)
                            Button("閉じる") { dismiss() }.buttonStyle(.plain)
                        }
                        .padding(28)
                    }
                } else if let errorMessage {
                    ContentUnavailableView("お守りを開けません", systemImage: "gift", description: Text(errorMessage))
                } else {
                    ProgressView("お守りを開いています")
                }
            }
            .navigationTitle("言葉のお守り")
            .task { await load() }
        }
    }

    private func load() async {
        do {
            gift = try await service.fetchGift(id: giftID)
            await service.markOpened(id: giftID)
        } catch { errorMessage = error.localizedDescription }
    }

    private func save(_ gift: GiftPublicPayload) {
        let quote = Quote(
            id: "gift_\(gift.id)", quoteJa: gift.quoteJa, author: gift.author,
            authorDescription: "言葉のお守り", category: .affirmation,
            punchline: gift.quoteJa, backgroundImage: gift.backgroundID,
            pushNotificationHook: gift.quoteJa, isFavorited: true, favoritedAt: Date()
        )
        modelContext.insert(quote)
        do {
            try modelContext.save()
            saved = true
            AnalyticsService.shared.logGift("gift_saved", params: [
                "days_since_issue": max(0, Calendar.current.dateComponents([.day], from: gift.createdAt, to: Date()).day ?? 0)
            ])
        } catch { errorMessage = error.localizedDescription }
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }
