import Foundation
import StoreKit

/// ⚠️ DEPRECATED: このファイルは使用されていません。
/// RevenueCatManager.swift に移行済みです。
/// Xcodeのプロジェクトから安全に削除できます。
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    @Published var isPremiumUser = false
    @Published var isLoading = false
    @Published var products: [Product] = []
    private init() {}
}

enum PurchaseError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "トランザクションの検証に失敗しました"
        case .productNotFound:
            return "商品が見つかりませんでした"
        }
    }
}
