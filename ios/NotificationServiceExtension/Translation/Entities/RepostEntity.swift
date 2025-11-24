// SPDX-License-Identifier: ice License 1.0

import Foundation

struct RepostData {
    let eventReference: EventReference

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> RepostData {
        var eventId: String? = nil
        var pubkey: String? = nil
        
        for tag in eventMessage.tags {
            if !tag.isEmpty {
                switch tag[0] {
                case "e":
                    if tag.count > 1 {
                        eventId = tag[1]
                    }
                case "p":
                    if tag.count > 1 {
                        pubkey = tag[1]
                    }
                default:
                    break
                }
            }
        }
        
        // Throw exception if required tags are missing
        if eventId == nil || pubkey == nil {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }
        
        return RepostData(
            eventReference: ImmutableEventReference(id: eventId!, pubkey: pubkey!)
        )
    }
}

struct RepostEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: RepostData

    static let kind = 6

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, data: RepostData) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> RepostEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()

        return RepostEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: try RepostData.fromEventMessage(eventMessage)
        )
    }
    
    func toEventReference() -> EventReference {
        return ImmutableEventReference(
            id: id,
            pubkey: pubkey,
            kind: RepostEntity.kind,
            masterPubkey: masterPubkey
        )
    }
}
