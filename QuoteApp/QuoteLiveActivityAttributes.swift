import ActivityKit
import Foundation

public struct QuoteLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var punchline: String
        public var author: String
        public var categoryJa: String
        
        public init(punchline: String, author: String, categoryJa: String) {
            self.punchline = punchline
            self.author = author
            self.categoryJa = categoryJa
        }
    }

    public init() {}
}
