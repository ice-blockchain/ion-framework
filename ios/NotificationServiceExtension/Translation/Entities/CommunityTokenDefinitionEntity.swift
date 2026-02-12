// SPDX-License-Identifier: ice License 1.0

import Foundation

struct CommunityTokenDefinitionData {
    let eventReference: EventReference
    let kind: Int
    let dTag: String
    
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> CommunityTokenDefinitionData {
        var dTag = ""
        var kind: Int?
        var eventReference: EventReference?
        
        let tagsByType = Dictionary(grouping: eventMessage.tags, by: { $0.first ?? "" })
        
        // Parse "d" tag (d-tag)
        if let dTagValue = tagsByType["d"]?.first, dTagValue.count > 1 {
            dTag = dTagValue[1]
        }
        
        // Parse "k" tag (kind)
        if let kTagValue = tagsByType["k"]?.first, kTagValue.count > 1 {
            kind = Int(kTagValue[1])
        }
        
        // Parse event reference from "a" or "e" tags
        if let aTag = tagsByType["a"]?.first, aTag.count > 1 {
            eventReference = ReplaceableEventReference.fromString(aTag[1])
        } else if let eTag = tagsByType["e"]?.first, eTag.count > 1 {
            let pTag = tagsByType["p"]?.first
            let pubkey = pTag?.count ?? 0 > 1 ? pTag?[1] : ""
            eventReference = ImmutableEventReference(id: eTag[1], pubkey: pubkey ?? "")
        }
        
        guard let kind = kind, let eventReference = eventReference else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }
        
        return CommunityTokenDefinitionData(
            eventReference: eventReference,
            kind: kind,
            dTag: dTag
        )
    }
}

struct CommunityTokenDefinitionEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: CommunityTokenDefinitionData
    
    static let kind = 31175
    
    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: CommunityTokenDefinitionData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }
    
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> CommunityTokenDefinitionEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }
        
        let masterPubkey = try eventMessage.masterPubkey()
        let data = try CommunityTokenDefinitionData.fromEventMessage(eventMessage)
        
        return CommunityTokenDefinitionEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: data
        )
    }
    
    func toEventReference() -> EventReference {
        return ReplaceableEventReference(
            masterPubkey: masterPubkey,
            kind: CommunityTokenDefinitionEntity.kind,
            dTag: data.dTag
        )
    }
}
