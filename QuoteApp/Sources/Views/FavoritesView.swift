import SwiftUI
import SwiftData

/// お気に入り一覧画面
struct FavoritesView: View {
    // MARK: - Properties

    @ObservedObject var quoteDataService: QuoteDataService
    @EnvironmentObject private var userSettings: UserSettings

    @State private var favoriteQuotes: [Quote] = []
    @State private var isLoading = true
    @State private var selectedQuote: Quote?
    @State private var showQuoteDetail = false

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if favoriteQuotes.isEmpty {
                    emptyStateView
                } else {
                    favoriteListView
                }
            }
            .navigationTitle("お気に入り")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .task {
                loadFavorites()
            }
            .sheet(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote, quoteDataService: quoteDataService)
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("お気に入りがありません")
                .font(.headline)
                .foregroundColor(.white)

            Text("名言を保存して、\nいつでも見返せるようにしましょう")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var favoriteListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(favoriteQuotes, id: \.id) { quote in
                    FavoriteQuoteCard(quote: quote)
                        .onTapGesture {
                            selectedQuote = quote
                            showQuoteDetail = true
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Methods

    private func loadFavorites() {
        isLoading = true

        do {
            favoriteQuotes = try quoteDataService.getFavoriteQuotes()
            isLoading = false
        } catch {
            print("⚠️ お気に入りの取得に失敗しました: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Favorite Quote Card

struct FavoriteQuoteCard: View {
    let quote: Quote

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // カテゴリバッジ
            Text(quote.category.displayText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentGold.opacity(0.3))
                .clipShape(Capsule())

            // 名言本文
            Text(quote.quoteJa)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(3)
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
}

// MARK: - Quote Detail View

struct QuoteDetailView: View {
    let quote: Quote
    @ObservedObject var quoteDataService: QuoteDataService
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false
    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 32) {
                // クローズボタン
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // 名言
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(accentGold)

                    Text(quote.quoteJa)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .lineSpacing(10)

                    Text("— \(quote.author)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // アクションボタン
                HStack(spacing: 20) {
                    Button(action: {
                        try? quoteDataService.toggleFavorite(quote: quote)
                        dismiss()
                    }) {
                        Label("保存解除", systemImage: "bookmark.slash.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(action: {
                        // シェア処理
                    }) {
                        Label("共有", systemImage: "square.and.arrow.up")
                            .foregroundColor(accentGold)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .opacity(appear ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appear = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([Quote.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let service = QuoteDataService(modelContext: context)

    FavoritesView(quoteDataService: service)
        .environmentObject(UserSettings())
        .modelContainer(container)
}
