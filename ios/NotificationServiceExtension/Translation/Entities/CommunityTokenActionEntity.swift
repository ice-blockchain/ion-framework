// SPDX-License-Identifier: ice License 1.0

import Foundation

struct CommunityTokenActionData {
    let definitionReference: EventReference
    let relatedPubkey: RelatedPubkey
    
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> CommunityTokenActionData {
        var eventReference: EventReference?
        var relatedPubkey: RelatedPubkey?
        
        let tagsByType = Dictionary(grouping: eventMessage.tags, by: { $0.first ?? "" })
        
        // Parse event reference from "a" or "e" tags
        if let aTag = tagsByType["a"]?.first, aTag.count > 1 {
            eventReference = ReplaceableEventReference.fromString(aTag[1])
        } else if let eTag = tagsByType["e"]?.first, eTag.count > 1 {
            let pTag = tagsByType["p"]?.first
            let pubkey = pTag?.count ?? 0 > 1 ? pTag?[1] : ""
            eventReference = ImmutableEventReference(id: eTag[1], pubkey: pubkey ?? "")
        }
        
        // Parse related pubkey from "p" tag
        if let pTag = tagsByType["p"]?.first {
            relatedPubkey = RelatedPubkey.fromTag(pTag)
        }
        
        guard let eventReference = eventReference, let relatedPubkey = relatedPubkey else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }
        
        return CommunityTokenActionData(
            definitionReference: eventReference,
            relatedPubkey: relatedPubkey
        )
    }
}

struct CommunityTokenActionEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: CommunityTokenActionData
    
    static let kind = 1175
    
    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: CommunityTokenActionData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }
    
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> CommunityTokenActionEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }
        
        let masterPubkey = try eventMessage.masterPubkey()
        let data = try CommunityTokenActionData.fromEventMessage(eventMessage)
        
        return CommunityTokenActionEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: data
        )
    }
}
