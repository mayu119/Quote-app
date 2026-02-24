import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var quotes: [Quote] = []
    @State private var isLoading = true
    @State private var showPremiumView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !userSettings.isPremiumUser {
                    lockedStateView
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else if quotes.isEmpty {
                    Text("No past quotes.")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.5))
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
            .navigationTitle("ARCHIVE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                .foregroundColor(.white.opacity(0.5))
            
            Text("PREMIUM ACCESS")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .tracking(4)
                .foregroundColor(.white)
            
            Button(action: {
                showPremiumView = true
            }) {
                Text("UNLOCK ARCHIVE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white)
            }
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let lastShown = quote.lastShownDate {
                    Text(formatDate(lastShown).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            }
            
            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W6", size: 18))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(8)
                .lineLimit(4)
            
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 20, height: 1)
                
                Text(quote.author.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
