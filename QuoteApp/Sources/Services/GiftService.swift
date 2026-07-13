import Foundation
import StoreKit

struct GiftPublicPayload: Codable, Identifiable {
    let id: String
    let quoteID: String
    let quoteJa: String
    let author: String
    let senderNote: String
    let backgroundID: String
    let createdAt: Date
    let expiresAt: Date
    let status: String
}

struct GiftRoute: Identifiable {
    let id: String
}

@MainActor
final class GiftLinkRouter: ObservableObject {
    @Published var route: GiftRoute?

    func handle(_ url: URL) {
        guard url.host == "mayu119.github.io" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 3, parts[0] == "Quote-app", parts[1] == "gift" else { return }
        route = GiftRoute(id: parts[2])
    }
}

@MainActor
final class GiftService: ObservableObject {
    static let shared = GiftService()

    @Published private(set) var product: Product?
    @Published private(set) var isWorking = false

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    enum GiftError: LocalizedError {
        case productUnavailable
        case purchaseCancelled
        case verificationFailed
        case invalidResponse
        case server(String)

        var errorDescription: String? {
            switch self {
            case .productUnavailable: return "言葉のお守りは、まだ購入できません。"
            case .purchaseCancelled: return nil
            case .verificationFailed: return "購入の確認に失敗しました。"
            case .invalidResponse: return "お守りの発行結果を確認できませんでした。"
            case .server(let message): return message
            }
        }
    }

    private init() {}

    func loadProduct() async {
        guard product == nil else { return }
        product = try? await Product.products(for: [Config.giftOmamoriProductID]).first
    }

    func purchaseAndIssue(quote: Quote, senderNote: String) async throws -> URL {
        isWorking = true
        defer { isWorking = false }
        await loadProduct()
        guard let product else { throw GiftError.productUnavailable }

        AnalyticsService.shared.logGift("gift_compose_started", params: ["source": "shelf"])
        let draft = try await prepare(quote: quote, senderNote: senderNote)
        AnalyticsService.shared.logGift("gift_purchase_initiated", params: ["product_id": product.id])

        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw GiftError.verificationFailed
            }
            let idempotencyKey = UUID().uuidString.lowercased()
            let issued = try await issue(
                draftID: draft.draftID,
                transactionID: String(transaction.id),
                signedTransaction: verification.jwsRepresentation,
                idempotencyKey: idempotencyKey
            )
            UserDefaults.standard.set(issued.url.absoluteString, forKey: "gift.issued.\(transaction.id)")
            await transaction.finish()
            AnalyticsService.shared.logGift("gift_purchase_succeeded", params: ["product_id": product.id])
            AnalyticsService.shared.logGift("gift_issued", params: ["background_id": quote.backgroundImage])
            return issued.url
        case .pending:
            throw GiftError.server("購入の承認待ちです。承認後に自動で確認します。")
        case .userCancelled:
            throw GiftError.purchaseCancelled
        @unknown default:
            throw GiftError.invalidResponse
        }
    }

    func fetchGift(id: String) async throws -> GiftPublicPayload {
        let url = Config.giftAPIBaseURL.appending(path: "v1/gifts/\(id)")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response, data: data)
        let payload = try decoder.decode(GiftPublicPayload.self, from: data)
        AnalyticsService.shared.logGift("gift_opened", params: [
            "surface": "app",
            "days_since_issue": max(0, Calendar.current.dateComponents([.day], from: payload.createdAt, to: Date()).day ?? 0)
        ])
        return payload
    }

    func markOpened(id: String) async {
        var request = URLRequest(url: Config.giftAPIBaseURL.appending(path: "v1/gifts/\(id)/opened"))
        request.httpMethod = "POST"
        _ = try? await URLSession.shared.data(for: request)
    }

    private func prepare(quote: Quote, senderNote: String) async throws -> DraftResponse {
        let payload = PrepareRequest(
            quoteID: quote.id,
            quoteJa: quote.quoteJa,
            author: quote.displayAuthor,
            senderNote: String(senderNote.prefix(60)),
            backgroundID: quote.backgroundImage
        )
        return try await post(path: "v1/gifts/prepare", payload: payload)
    }

    private func issue(draftID: String, transactionID: String, signedTransaction: String, idempotencyKey: String) async throws -> IssueResponse {
        let payload = IssueRequest(
            draftID: draftID,
            transactionID: transactionID,
            signedTransaction: signedTransaction,
            idempotencyKey: idempotencyKey
        )
        return try await post(path: "v1/gifts/issue", payload: payload)
    }

    private func post<Request: Encodable, Response: Decodable>(path: String, payload: Request) async throws -> Response {
        var request = URLRequest(url: Config.giftAPIBaseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(Response.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw GiftError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerError.self, from: data).error) ?? "お守りサーバーでエラーが発生しました。"
            throw GiftError.server(message)
        }
    }
}

private struct PrepareRequest: Encodable {
    let quoteID: String
    let quoteJa: String
    let author: String
    let senderNote: String
    let backgroundID: String
}

private struct DraftResponse: Decodable { let draftID: String }

private struct IssueRequest: Encodable {
    let draftID: String
    let transactionID: String
    let signedTransaction: String
    let idempotencyKey: String
}

private struct IssueResponse: Decodable { let url: URL }
private struct ServerError: Decodable { let error: String }
