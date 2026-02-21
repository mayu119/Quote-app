import SwiftUI

// MARK: - Main View
struct MainQuoteView: View {
    let quote = Quote(
        text: "考えるな、動け。\nお前が悩んでいる間に、\nライバルはもう行動している。",
        author: "Unknown",
        category: "🔥 覚醒・行動",
        imageName: "bg_dark_gym" // 実際はシネマティックな暗黒背景画像
    )
    
    @State private var isLiked = false
    @State private var showSettings = false
    @State private var appear = false 
    
    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)
    
    var body: some View {
        // UIレイヤーをルートにすることで、画面幅（セーフエリア）に確実に制限します
        VStack(alignment: .leading, spacing: 0) {
            headerLayer
            
            Spacer()
            
            quoteLayer
            
            Spacer()
            
            bottomActionLayer
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // 1. プレミアムシネマティック背景（全画面を完全に覆う）
            ZStack {
                Color.black
                
                Image("majestic_peak")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(appear ? 1.05 : 1.0)
                    .animation(.linear(duration: 20).repeatForever(autoreverses: true), value: appear)
                
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
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                appear = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerLayer: some View {
        HStack {
            HStack(spacing: 6) {
                Text(quote.category)
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
    
    private var quoteLayer: some View {
        VStack(alignment: .leading, spacing: 32) {
            Image(systemName: "quote.opening")
                .font(.system(size: 48, weight: .black))
                .foregroundColor(accentGold)
                .shadow(color: accentGold.opacity(0.4), radius: 12, x: 0, y: 4)
            
            Text(quote.text)
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
    
    private var bottomActionLayer: some View {
        HStack(spacing: 40) {
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLiked.toggle()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: isLiked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isLiked ? accentGold : .white.opacity(0.8))
                        .scaleEffect(isLiked ? 1.15 : 1.0)
                    
                    Text("保存")
                        .font(.custom("HiraginoSans-W6", size: 10))
                        .tracking(1)
                        .foregroundColor(isLiked ? .white : .white.opacity(0.6))
                }
                .frame(width: 60, height: 60)
            }
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
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
}

// MARK: - Preview
struct MainQuoteView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainQuoteView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
                .previewDisplayName("Pro Max (15)")
            MainQuoteView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("SE (3rd Gen)")
        }
    }
}
