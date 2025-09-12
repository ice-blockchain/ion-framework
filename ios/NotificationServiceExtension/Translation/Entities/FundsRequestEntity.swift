// SPDX-License-Identifier: ice License 1.0

import Foundation

/// Matches the JSON stored in `eventMessage.content` for kind 1755:
/// {
///   "from": "...",
///   "to": "...",
///   "assetId": "optional",
///   "amount": "optional",
///   "amountUsd": "optional"
/// }
private struct FundsRequestContent: Codable {
    let from: String
    let to: String
    let assetId: String?
    let amount: String?
    let amountUsd: String?
}

struct FundsRequestData {
    let amount: String
    let recipient: String
    let assetId: String?

    /// Parses a 1755 event strictly from its JSON content.
    /// Throws if the content is not valid JSON for `FundsRequestContent`.
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> FundsRequestData {
        guard let data = eventMessage.content.data(using: .utf8) else {
            throw NSError(
                domain: "FundsRequestData",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 in 1755 content"]
            )
        }

        let content = try JSONDecoder().decode(FundsRequestContent.self, from: data)

        return FundsRequestData(
            amount: content.amount ?? "",
            recipient: content.to,
            assetId: content.assetId
        )
    }
}

struct FundsRequestEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: FundsRequestData

    static let kind = 1755

    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: FundsRequestData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> FundsRequestEntity {
        // Support two inputs:
        //  - kind 1755 (FundsRequest) -> parse directly from its JSON content
        //  - kind 30014 (RDM) with "payment-requested" tag that embeds a 1755 JSON -> extract and parse
        if eventMessage.kind == kind {
            let masterPubkey = try eventMessage.masterPubkey()
            return FundsRequestEntity(
                id: eventMessage.id,
                pubkey: eventMessage.pubkey,
                masterPubkey: masterPubkey,
                signature: eventMessage.sig ?? "",
                createdAt: eventMessage.createdAt,
                data: try FundsRequestData.fromEventMessage(eventMessage)
            )
        } else if eventMessage.kind == ReplaceablePrivateDirectMessageEntity.kind {
            // Try to rebuild the embedded 1755 from the "payment-requested" tag
            do {
                let chat = try ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage)

                guard let fundsRequestJson = chat.data.paymentRequested,
                      let fundsRequestData = fundsRequestJson.data(using: .utf8) else {
                    throw NSError(
                        domain: "FundsRequestEntity",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Missing payment-requested tag on 30014"]
                    )
                }

                // Decode the embedded 1755 EventMessage JSON
                let fundsRequestEvent = try JSONDecoder().decode(EventMessage.self, from: fundsRequestData)

                // Parse the inner 1755 using the standard path (which also logs content + recipient comparison)
                let inner = try FundsRequestEntity.fromEventMessage(fundsRequestEvent)
                return inner
            } catch {
                throw error
            }
        } else {
            // Neither a 1755 nor a 30014 carrier
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }
    }
}