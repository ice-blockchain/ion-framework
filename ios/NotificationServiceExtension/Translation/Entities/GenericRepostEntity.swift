// SPDX-License-Identifier: ice License 1.0

import Foundation

struct GenericRepostData {
    let eventReference: EventReference

    static func fromEventMessage(_ eventMessage: EventMessage) -> GenericRepostData {
        let tagsByType = Dictionary(grouping: eventMessage.tags, by: { $0.first ?? "" })

        let aTag = tagsByType["a"]?.first
        let eTag = tagsByType["e"]?.first
        let pTag = tagsByType["p"]?.first
        
        if let aTag = aTag, aTag.count > 1 {
            let eventReference = ReplaceableEventReference.fromString(aTag[1])
            return GenericRepostData(eventReference: eventReference)
        } else if let eTag = eTag, eTag.count > 1, let pubkey = pTag?.count ?? 0 > 1 ? pTag?[1] : nil {
            let eventId = eTag[1]
            return GenericRepostData(eventReference: ImmutableEventReference(id: eventId, pubkey: pubkey))
        }

        return GenericRepostData(eventReference: ImmutableEventReference(id: "", pubkey: ""))
    }
}

struct GenericRepostEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: GenericRepostData

    static let kind = 16

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, data: GenericRepostData) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> GenericRepostEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()

        return GenericRepostEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: GenericRepostData.fromEventMessage(eventMessage)
        )
    }
    
    func toEventReference() -> EventReference {
        return ImmutableEventReference(
            id: id,
            pubkey: pubkey,
            kind: GenericRepostEntity.kind,
            masterPubkey: masterPubkey
        )
    }
}
