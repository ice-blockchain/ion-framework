// SPDX-License-Identifier: ice License 1.0

import Foundation

struct TokenBuyingActivityResponseEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int

    static let kind = 6178

    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenBuyingActivityResponseEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()

        return TokenBuyingActivityResponseEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt
        )
    }
}
