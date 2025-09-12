// SPDX-License-Identifier: ice License 1.0

import Foundation
import NostrSDK

struct IonConnectGiftWrapData {
    let kinds: [String]
    let relatedPubkeys: [RelatedPubkey]

    static func fromEventMessage(_ eventMessage: EventMessage) -> IonConnectGiftWrapData {
        // Collect *all* values from "k" tags (outer and inner kinds), not just the first value.
        let kinds: [String] = eventMessage.tags
            .filter { $0.count >= 2 && $0[0] == "k" }
            .flatMap { Array($0.dropFirst()) }

        // Parse related pubkeys from p tags
        let relatedPubkeys = eventMessage.tags.compactMap { tag -> RelatedPubkey? in
            if tag.count >= 2 && tag[0] == "p" {
                return RelatedPubkey.fromTag(tag)
            }
            return nil
        }

        return IonConnectGiftWrapData(
            kinds: kinds,
            relatedPubkeys: relatedPubkeys
        )
    }
}

struct IonConnectGiftWrapEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: IonConnectGiftWrapData

    static let kind = 1059

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, data: IonConnectGiftWrapData) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> IonConnectGiftWrapEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        return IonConnectGiftWrapEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: eventMessage.pubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: IonConnectGiftWrapData.fromEventMessage(eventMessage)
        )
    }
}
