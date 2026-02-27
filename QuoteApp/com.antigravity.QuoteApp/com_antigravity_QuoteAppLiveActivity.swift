import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity UI

@available(iOS 16.1, *)
struct com_antigravity_QuoteAppLiveActivity: Widget {
    
    // アプリと統一感のあるアクセントゴールド
    let accentGold = Color(red: 0.85, green: 0.75, blue: 0.45)
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuoteLiveActivityAttributes.self) { context in
            // MARK: - Lock Screen & Banner UI
            ZStack {
                // 背景 (Obsidian風)
                Color.black.opacity(0.8)
                
                VStack(spacing: 6) {
                    HStack {
                        Text(context.state.categoryJa)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(accentGold)
                        Spacer()
                    }
                    
                    Text(context.state.punchline)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Spacer()
                        Text("— \(context.state.author)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            // MARK: - Dynamic Island UI
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.categoryJa)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentGold)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "quote.closing")
                        .foregroundColor(.white.opacity(0.4))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.punchline)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text("— \(context.state.author)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "quote.opening")
                    .foregroundColor(accentGold)
            } compactTrailing: {
                Text(context.state.author.prefix(5))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "quote.closing")
                    .foregroundColor(accentGold)
            }
            .widgetURL(URL(string: "quoteapp://open"))
            .keylineTint(accentGold)
        }
    }
}
