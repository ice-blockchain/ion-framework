// SPDX-License-Identifier: ice License 1.0

import Foundation

struct TransactionAmount {
    let value: Double
    let currency: String
    
    static let tagName = "tx_amount"
    static let usdCurrency = "USD"
    
    static func fromTag(_ tag: [String]) -> TransactionAmount? {
        guard tag.count >= 3,
              tag[0] == tagName,
              let value = Double(tag[1]) else {
            return nil
        }
        return TransactionAmount(value: value, currency: tag[2])
    }
}

struct CommunityTokenActionData {
    let definitionReference: EventReference
    let relatedPubkey: RelatedPubkey
    let amounts: [TransactionAmount]
    let tokenTicker: String
    let kind: Int
    
    func getAmountByCurrency(_ currency: String) -> TransactionAmount? {
        return amounts.first { $0.currency == currency }
    }
    
    func getUsdAmount() -> TransactionAmount? {
        return getAmountByCurrency(TransactionAmount.usdCurrency)
    }
    
    func getTokenAmount() -> TransactionAmount? {
        return amounts.first { $0.currency == tokenTicker }
    }
    
    static func fromEventMessage(_ eventMessage: EventMessage) throws -> CommunityTokenActionData {
        var eventReference: EventReference?
        var relatedPubkey: RelatedPubkey?
        var amounts: [TransactionAmount] = []
        var tokenTicker = ""
        var kind: Int?
        
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
        
        // Parse transaction amounts
        if let amountTags = tagsByType[TransactionAmount.tagName] {
            amounts = amountTags.compactMap { TransactionAmount.fromTag($0) }
        }
        
        // Parse token ticker/symbol
        if let tickerTag = tagsByType["token_symbol"]?.first, tickerTag.count > 1 {
            tokenTicker = tickerTag[1]
        }
        
        // Parse "k" tag (kind)
        if let kTagValue = tagsByType["k"]?.first, kTagValue.count > 1 {
            kind = Int(kTagValue[1])
        }
        
        guard let eventReference = eventReference, let relatedPubkey = relatedPubkey, let kind = kind else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }
        
        return CommunityTokenActionData(
            definitionReference: eventReference,
            relatedPubkey: relatedPubkey,
            amounts: amounts,
            tokenTicker: tokenTicker,
            kind: kind
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
