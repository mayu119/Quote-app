import SwiftUI
import SwiftData

struct FavoritesView: View {
    @ObservedObject var quoteDataService: QuoteDataService
    
    @State private var favoriteQuotes: [Quote] = []
    @State private var isLoading = true
    @State private var selectedQuote: Quote?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else if favoriteQuotes.isEmpty {
                    VStack(spacing: 32) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No saved quotes.")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 40) {
                            ForEach(favoriteQuotes, id: \.id) { quote in
                                MinimalFavoriteCard(quote: quote)
                                    .onTapGesture {
                                        selectedQuote = quote
                                    }
                            }
                        }
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("SAVED")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                loadFavorites()
            }
            .fullScreenCover(item: $selectedQuote) { quote in
                MinimalQuoteDetailView(quote: quote, quoteDataService: quoteDataService)
            }
        }
    }
    
    private func loadFavorites() {
        isLoading = true
        do {
            favoriteQuotes = try quoteDataService.getFavoriteQuotes()
            isLoading = false
        } catch {
            print("⚠️ Error loading: \(error)")
            isLoading = false
        }
    }
}

struct MinimalFavoriteCard: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
}

struct MinimalQuoteDetailView: View {
    let quote: Quote
    @ObservedObject var quoteDataService: QuoteDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var appear = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top Header (Close)
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    }
                }
                
                Spacer()
                
                // Content
                VStack(alignment: .leading, spacing: 40) {
                    Text(quote.quoteJa)
                        .font(.custom("HiraginoSans-W8", size: 36))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .lineSpacing(14)
                        .minimumScaleFactor(0.4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 20) {
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 40, height: 1)
                        
                        Text(quote.author.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .tracking(6)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
                
                Spacer()
                
                // Actions
                HStack(spacing: 40) {
                    Button(action: {
                        try? quoteDataService.toggleFavorite(quote: quote)
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "bookmark.slash")
                                .font(.system(size: 20, weight: .light))
                            Text("REMOVE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Button(action: {
                        // Share
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .light))
                            Text("SHARE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                appear = true
            }
        }
    }
}
