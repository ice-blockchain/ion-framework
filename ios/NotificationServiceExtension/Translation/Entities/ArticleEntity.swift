// SPDX-License-Identifier: ice License 1.0

import Foundation

struct ArticleData {
    let replaceableEventId: String
    
    static func fromEventMessage(_ eventMessage: EventMessage) -> ArticleData {
        var dTag = ""
        
        for tag in eventMessage.tags {
            if tag.count >= 2 && tag[0] == "d" {
                dTag = tag[1]
                break
            }
        }
        
        return ArticleData(replaceableEventId: dTag)
    }
}

struct ArticleEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: ArticleData
    
    static let kind = 30023
    
    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: ArticleData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }
    
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> ArticleEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }
        
        let masterPubkey = try eventMessage.masterPubkey()
        
        return ArticleEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: ArticleData.fromEventMessage(eventMessage)
        )
    }
    
    func toEventReference() -> EventReference {
        return ReplaceableEventReference(
            masterPubkey: masterPubkey,
            kind: ArticleEntity.kind,
            dTag: data.replaceableEventId
        )
    }
}
