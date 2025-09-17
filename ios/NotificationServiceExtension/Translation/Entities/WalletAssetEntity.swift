// SPDX-License-Identifier: ice License 1.0


import Foundation

/// Matches the JSON stored in `eventMessage.content` for kind 1756:
/// {
///   "txUrl": "https://...",
///   "txHash": "...",
///   "from": "...",
///   "to": "...",
///   "assetId": "optional",
///   "amount": "optional",
///   "amountUsd": "optional"
/// }
private struct WalletAssetContent: Codable {
    let txUrl: String?
    let txHash: String?
    let from: String?
    let to: String?
    let assetId: String?
    let amount: String?
    let amountUsd: String?
}

struct WalletAssetData {
    let amount: String
    let recipient: String
    let assetId: String?

    /// Parses a 1756 event strictly from its JSON content.
    /// Throws if the content is not valid JSON for `WalletAssetContent`.
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> WalletAssetData {
        guard let data = eventMessage.content.data(using: .utf8) else {
            throw NSError(
                domain: "WalletAssetData",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 in 1756 content"]
            )
        }

        let content = try JSONDecoder().decode(WalletAssetContent.self, from: data)

        return WalletAssetData(
            amount: content.amount ?? "",
            recipient: content.to ?? "",
            assetId: content.assetId
        )
    }
}

struct WalletAssetEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: WalletAssetData

    static let kind = 1756

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, data: WalletAssetData) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> WalletAssetEntity {
        // Support two inputs:
        //  - kind 1756 (WalletAsset) -> parse directly from its JSON content
        //  - kind 30014 (RDM) with "payment-sent" tag that embeds a 1756 JSON -> extract and parse
        if eventMessage.kind == kind {
            let masterPubkey = try eventMessage.masterPubkey()
            return WalletAssetEntity(
                id: eventMessage.id,
                pubkey: eventMessage.pubkey,
                masterPubkey: masterPubkey,
                signature: eventMessage.sig ?? "",
                createdAt: eventMessage.createdAt,
                data: try WalletAssetData.fromEventMessage(eventMessage)
            )
        } else if eventMessage.kind == ReplaceablePrivateDirectMessageEntity.kind {
            // Try to rebuild the embedded 1756 from the "payment-sent" tag
            let chat = try ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage)

            guard let walletAssetJson = chat.data.paymentSent,
                  let walletAssetData = walletAssetJson.data(using: .utf8) else {
                throw NSError(
                    domain: "WalletAssetEntity",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Missing payment-sent tag on 30014"]
                )
            }

            // Decode the embedded 1756 EventMessage JSON
            let walletAssetEvent = try JSONDecoder().decode(EventMessage.self, from: walletAssetData)
            // Parse the inner 1756 using the standard path
            return try WalletAssetEntity.fromEventMessage(walletAssetEvent)
        } else {
            // Neither a 1756 nor a 30014 carrier
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }
    }
}
