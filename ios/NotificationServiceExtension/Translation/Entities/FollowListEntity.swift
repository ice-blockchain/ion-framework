// SPDX-License-Identifier: ice License 1.0

import Foundation

struct FollowListEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let pubkeys: [String]

    static let kind = 3

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, pubkeys: [String]) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.pubkeys = pubkeys
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> FollowListEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()

        // Parse pubkeys from p tags
        let pubkeys = eventMessage.tags.compactMap { tag -> String? in
            if tag.count >= 2 && tag[0] == "p" {
                return tag[1]
            }
            return nil
        }

        return FollowListEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            pubkeys: pubkeys
        )
    }
    
    func toEventReference() -> EventReference {
        return ImmutableEventReference(
            id: id,
            pubkey: pubkey,
            kind: FollowListEntity.kind,
            masterPubkey: masterPubkey
        )
    }
}
