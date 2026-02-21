import SwiftUI
import SwiftData

/// 今日の名言表示ビュー
struct TodayQuoteView: View {
    // MARK: - Properties

    @ObservedObject var quoteDataService: QuoteDataService
    @EnvironmentObject private var userSettings: UserSettings

    @State private var currentQuote: Quote?
    @State private var isLoading = true
    @State private var showSettings = false
    @State private var appear = false
    @State private var showShareSheet = false

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    // MARK: - Body

    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if let quote = currentQuote {
                quoteContentView(quote: quote)
            } else {
                errorView
            }
        }
        .task {
            await loadTodayQuote()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }

    private var errorView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)

                Text("名言を読み込めませんでした")
                    .font(.headline)
                    .foregroundColor(.white)

                Button("再試行") {
                    Task {
                        await loadTodayQuote()
                    }
                }
                .foregroundColor(accentGold)
            }
        }
    }

    private func quoteContentView(quote: Quote) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerLayer(quote: quote)

            Spacer()

            quoteLayer(quote: quote)

            Spacer()

            bottomActionLayer(quote: quote)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundLayer(imageName: quote.backgroundImage))
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                appear = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(quote: quote)
        }
    }

    private func headerLayer(quote: Quote) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text(quote.category.displayText)
                    .font(.custom("HiraginoSans-W6", size: 12))
                    .tracking(1)
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            Spacer()

            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showSettings.toggle()
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
        }
        .padding(.top, 16)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : -20)
    }

    private func quoteLayer(quote: Quote) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            Image(systemName: "quote.opening")
                .font(.system(size: 48, weight: .black))
                .foregroundColor(accentGold)
                .shadow(color: accentGold.opacity(0.4), radius: 12, x: 0, y: 4)

            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W8", size: 36))
                .foregroundColor(.white)
                .lineSpacing(12)
                .minimumScaleFactor(0.4)
                .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Rectangle()
                    .fill(accentGold)
                    .frame(width: 32, height: 2)
                    .shadow(color: .black, radius: 4, x: 0, y: 2)

                Text(quote.author.uppercased())
                    .font(.custom("HiraginoSans-W6", size: 16))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.trailing, 20)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
    }

    private func bottomActionLayer(quote: Quote) -> some View {
        HStack(spacing: 40) {
            // お気に入りボタン
            Button(action: {
                toggleFavorite(quote: quote)
            }) {
                VStack(spacing: 8) {
                    Image(systemName: quote.isFavorited ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(quote.isFavorited ? accentGold : .white.opacity(0.8))
                        .scaleEffect(quote.isFavorited ? 1.15 : 1.0)

                    Text("保存")
                        .font(.custom("HiraginoSans-W6", size: 10))
                        .tracking(1)
                        .foregroundColor(quote.isFavorited ? .white : .white.opacity(0.6))
                }
                .frame(width: 60, height: 60)
            }

            // シェアボタン
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showShareSheet = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Text("共有")
                        .font(.custom("HiraginoSans-W6", size: 10))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 60, height: 60)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
    }

    private func backgroundLayer(imageName: String) -> some View {
        ZStack {
            Color.black

            // 背景画像（存在する場合）
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(appear ? 1.05 : 1.0)
                    .animation(.linear(duration: 20).repeatForever(autoreverses: true), value: appear)
            } else {
                // フォールバック: majestic_peak
                Image("majestic_peak")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(appear ? 1.05 : 1.0)
                    .animation(.linear(duration: 20).repeatForever(autoreverses: true), value: appear)
            }

            // ダークグラデーション
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Methods

    private func loadTodayQuote() async {
        isLoading = true

        do {
            let quote = try await quoteDataService.getTodayQuote()
            await MainActor.run {
                self.currentQuote = quote
                self.isLoading = false
            }
        } catch {
            print("⚠️ 今日の名言の取得に失敗しました: \(error)")
            await MainActor.run {
                self.currentQuote = Quote.fallback
                self.isLoading = false
            }
        }
    }

    private func toggleFavorite(quote: Quote) {
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            do {
                try quoteDataService.toggleFavorite(quote: quote)
            } catch {
                print("⚠️ お気に入りの切り替えに失敗しました: \(error)")
            }
        }
    }
}

// MARK: - Share Sheet (Temporary Placeholder)

struct ShareSheetView: View {
    let quote: Quote

    var body: some View {
        VStack(spacing: 20) {
            Text("シェア機能")
                .font(.headline)

            Text(quote.quoteJa)
                .multilineTextAlignment(.center)
                .padding()

            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(.gray)

            Button("閉じる") {
                // Dismiss
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([Quote.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let service = QuoteDataService(modelContext: context)

    TodayQuoteView(quoteDataService: service)
        .environmentObject(UserSettings())
        .modelContainer(container)
}
