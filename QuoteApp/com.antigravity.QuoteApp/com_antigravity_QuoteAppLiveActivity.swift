//
//  com_antigravity_QuoteAppLiveActivity.swift
//  com.antigravity.QuoteApp
//
//  Created by 林真幸 on 2026/02/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct com_antigravity_QuoteAppAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct com_antigravity_QuoteAppLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: com_antigravity_QuoteAppAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension com_antigravity_QuoteAppAttributes {
    fileprivate static var preview: com_antigravity_QuoteAppAttributes {
        com_antigravity_QuoteAppAttributes(name: "World")
    }
}

extension com_antigravity_QuoteAppAttributes.ContentState {
    fileprivate static var smiley: com_antigravity_QuoteAppAttributes.ContentState {
        com_antigravity_QuoteAppAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: com_antigravity_QuoteAppAttributes.ContentState {
         com_antigravity_QuoteAppAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: com_antigravity_QuoteAppAttributes.preview) {
   com_antigravity_QuoteAppLiveActivity()
} contentStates: {
    com_antigravity_QuoteAppAttributes.ContentState.smiley
    com_antigravity_QuoteAppAttributes.ContentState.starEyes
}
