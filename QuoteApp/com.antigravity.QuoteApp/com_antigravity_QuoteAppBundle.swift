import WidgetKit
import SwiftUI

@main
struct com_antigravity_QuoteAppBundle: WidgetBundle {
    var body: some Widget {
        QuoteWidget()
        if #available(iOS 16.1, *) {
            com_antigravity_QuoteAppLiveActivity()
        }
    }
}
