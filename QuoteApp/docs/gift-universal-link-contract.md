# 言葉のお守り Universal Link 契約

受け取りURLは https://mayu119.github.io/Quote-app/gift/<gift-id> とする。

- Web: アプリ未導入時も、言葉・贈り主の一言・背景を無料で表示する。購入/ペイウォールは置かない。
- App: Associated Domains でこのURLを受け取り、GiftReceiveView を表示して棚への保存だけを提供する。
- API: gift-id は推測不能なUUID。本文・贈り主メモ・背景・作成日時を返し、受取側の識別情報を保存しない。
- 運用: /.well-known/apple-app-site-association に appID: 9W24U28U8Q.com.antigravity.QuoteApp、paths: [/Quote-app/gift/*] を配信する。

App Store Connect API keyが利用できる環境では、次を先にdry-runする。

    scripts/sync_iap.py --spec QuoteApp/iap-config.json --issuer-id <ISSUER_ID> --key-id <KEY_ID> --private-key <AUTH_KEY.p8> --bundle-id com.antigravity.QuoteApp --dry-run
