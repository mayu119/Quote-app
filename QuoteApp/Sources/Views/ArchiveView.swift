import SwiftUI
import SwiftData

/// アーカイブ画面（プレミアム限定）
/// 過去の名言を無制限に閲覧
struct ArchiveView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings

    // MARK: - State

    @State private var quotes: [Quote] = []
    @State private var isLoading = true
    @State private var selectedCategory: QuoteCategory?
    @State private var showPremiumView = false

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if !userSettings.isPremiumUser {
                    premiumPromptView
                } else if isLoading {
                    loadingView
                } else {
                    archiveContent
                }
            }
            .navigationTitle("アーカイブ")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .task {
                if userSettings.isPremiumUser {
                    loadQuotes()
                }
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
    }

    private var premiumPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(accentGold)

            Text("プレミアム限定")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("過去の名言を無制限で閲覧するには\nプレミアムプランが必要です")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                showPremiumView = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("プレミアムにアップグレード")
                        .font(.headline)
                }
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: 300)
                .background(accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
    }

    private var archiveContent: some View {
        VStack(spacing: 0) {
            // カテゴリフィルター
            categoryFilter

            // 名言リスト
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredQuotes, id: \.id) { quote in
                        ArchiveQuoteCard(quote: quote)
                    }
                }
                .padding()
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全て
                CategoryChip(
                    title: "全て",
                    isSelected: selectedCategory == nil,
                    accentGold: accentGold
                ) {
                    selectedCategory = nil
                }

                // カテゴリ別
                ForEach(QuoteCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayText,
                        isSelected: selectedCategory == category,
                        accentGold: accentGold
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }

    private var filteredQuotes: [Quote] {
        if let category = selectedCategory {
            return quotes.filter { $0.category == category }
        }
        return quotes
    }

    // MARK: - Methods

    private func loadQuotes() {
        isLoading = true

        do {
            let descriptor = FetchDescriptor<Quote>(
                sortBy: [SortDescriptor(\.lastShownDate, order: .reverse)]
            )
            quotes = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            print("⚠️ アーカイブの読み込みに失敗しました: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Archive Quote Card

struct ArchiveQuoteCard: View {
    let quote: Quote

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // カテゴリ & 日付
            HStack {
                Text(quote.category.displayText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentGold.opacity(0.3))
                    .clipShape(Capsule())

                Spacer()

                if let lastShown = quote.lastShownDate {
                    Text(formatDate(lastShown))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            // 名言本文
            Text(quote.quoteJa)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(4)
                .lineSpacing(6)

            // 偉人名
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let accentGold: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? accentGold : Color.white.opacity(0.1)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([Quote.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    ArchiveView()
        .environmentObject(UserSettings())
        .modelContainer(container)
}
