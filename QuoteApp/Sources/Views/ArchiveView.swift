import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var quotes: [Quote] = []
    @State private var isLoading = true
    @State private var showPremiumView = false

    private let accentRose = Color(red: 0.86, green: 0.55, blue: 0.60)
    private let ink = Color(red: 0.31, green: 0.24, blue: 0.24)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.95, blue: 0.93),
                        Color(red: 0.97, green: 0.92, blue: 0.90),
                        Color(red: 0.95, green: 0.94, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if !userSettings.isPremiumUser {
                    lockedStateView
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentRose))
                        .scaleEffect(1.2)
                } else if quotes.isEmpty {
                    Text("まだ過去の言葉はありません。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ink.opacity(0.56))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 40) {
                            ForEach(quotes, id: \.id) { quote in
                                MinimalArchiveCard(quote: quote)
                            }
                        }
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("アーカイブ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.98, green: 0.94, blue: 0.93), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .task {
                if userSettings.isPremiumUser {
                    loadQuotes()
                }
            }
            .fullScreenCover(isPresented: $showPremiumView) {
                PremiumView()
            }
        }
    }
    
    private var lockedStateView: some View {
        VStack(spacing: 40) {
            Image(systemName: "lock")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(accentRose.opacity(0.6))
            
            Text("プレミアムでアーカイブ解放")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ink)
            
            Button(action: {
                showPremiumView = true
            }) {
                Text("アーカイブを見る")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(accentRose)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 28)
    }
    
    private func loadQuotes() {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<Quote>(
                sortBy: [SortDescriptor(\.lastShownDate, order: .reverse)]
            )
            quotes = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            print("⚠️ Error loading: \(error)")
            isLoading = false
        }
    }
}

struct MinimalArchiveCard: View {
    let quote: Quote
    private let accentRose = Color(red: 0.86, green: 0.55, blue: 0.60)
    private let ink = Color(red: 0.31, green: 0.24, blue: 0.24)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let lastShown = quote.lastShownDate {
                    Text(formatDate(lastShown))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ink.opacity(0.5))
                }
                Spacer()
            }
            
            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W6", size: 18))
                .foregroundColor(ink)
                .lineSpacing(8)
                .lineLimit(4)
            
            if quote.hasVisibleAuthorAttribution {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(accentRose.opacity(0.5))
                        .frame(width: 20, height: 1)
                    
                    Text(quote.displayAuthor)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(ink.opacity(0.56))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: accentRose.opacity(0.10), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
