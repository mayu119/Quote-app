import SwiftUI

// MARK: - Model
struct Quote {
    let text: String
    let author: String
    let category: String
    let imageName: String // 背景画像用（一旦プレースホルダー）
}

// MARK: - Main View
struct MainQuoteView: View {
    
    // サンプルデータ
    let quote = Quote(
        text: "考えるな、動け。\nお前が悩んでいる間に、\nライバルはもう行動している。",
        author: "Unknown",
        category: "🔥 覚醒・行動",
        imageName: "bg_dark_gym" // 実際はシネマティックな暗黒背景
    )
    
    @State private var isLiked = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // 1. 背景層 (画像 + ダークグラデーション)
            // ※ 画像がない場合は黒ベースのグラデーションで代用
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 背景画像のモック（本番はImageを使う）
             Image(systemName: "figure.strengthtraining.traditional")
                 .resizable()
                 .scaledToFit()
                 .foregroundColor(.white.opacity(0.05))
                 .frame(width: 300)
                 .offset(x: 50, y: -100)
            
            VStack {
                // 2. ヘッダー (設定など)
                HStack {
                    Text(quote.category)
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // 3. メインコンテンツ (名言 + 偉人名)
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white.opacity(0.2))
                        .offset(x: -10)
                    
                    Text(quote.text)
                        .font(.system(size: 32, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                        .lineSpacing(10)
                        .minimumScaleFactor(0.5)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text("— \(quote.author)")
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // 4. アクション層 (お気に入り・シェア)
                HStack(spacing: 40) {
                    // お気に入りボタン
                    Button(action: {
                        let impactLight = UIImpactFeedbackGenerator(style: .medium)
                        impactLight.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            isLiked.toggle()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(isLiked ? .red : .white.opacity(0.8))
                                .scaleEffect(isLiked ? 1.2 : 1.0)
                            
                            Text("保存")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // シェアボタン
                    Button(action: {
                        // シェア処理 (画像生成など)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("共有")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Preview
struct MainQuoteView_Previews: PreviewProvider {
    static var previews: some View {
        MainQuoteView()
    }
}
