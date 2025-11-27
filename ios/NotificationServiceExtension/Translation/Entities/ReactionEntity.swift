// SPDX-License-Identifier: ice License 1.0

import Foundation

struct ReactionData {
    let kind: Int
    let content: String
    let eventReference: EventReference

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> ReactionData {
        let content = eventMessage.content
        
        var tagGroups: [String: [[String]]] = [:]
        for tag in eventMessage.tags {
            if !tag.isEmpty {
                let key = tag[0]
                if tagGroups[key] == nil {
                    tagGroups[key] = []
                }
                tagGroups[key]?.append(tag)
            }
        }
        
        let eventId = tagGroups["e"]?.first?[1]
        let eventRef = tagGroups["a"]?.first?[1]
        let pubkey = tagGroups["p"]?.first?[1]
        let kindStr = tagGroups["k"]?.first?[1]
        
        guard let pubkey = pubkey, let kindStr = kindStr, let kind = Int(kindStr) else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }
        
        var eventReference: EventReference?
        
        if let eventRef = eventRef {
            eventReference = ReplaceableEventReference.fromString(eventRef)
        } else if let eventId = eventId {
            eventReference = ImmutableEventReference(id: eventId, pubkey: pubkey)
        }
        
        guard let eventReference = eventReference else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }
        
        return ReactionData(
            kind: kind,
            content: content,
            eventReference: eventReference
        )
    }
}

struct ReactionEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: ReactionData

    static let kind = 7
    static let likeSymbol = "+"

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, data: ReactionData) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> ReactionEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()

        return ReactionEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: try ReactionData.fromEventMessage(eventMessage)
        )
    }
    
    func toEventReference() -> EventReference {
        return ImmutableEventReference(
            id: id,
            pubkey: pubkey,
            kind: ReactionEntity.kind,
            masterPubkey: masterPubkey
        )
    }
}
