// SPDX-License-Identifier: ice License 1.0

import Foundation

struct TokenPriceChangeRequestParams {
    let deltaPercentage: Int

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenPriceChangeRequestParams {
        var deltaPercentage: Int?

        for tag in eventMessage.tags where tag.count > 2 && tag[0] == "param" {
            if tag[1] == "deltaPercentage" {
                deltaPercentage = Int(tag[2])
            }
        }

        guard let deltaPercentage else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        return TokenPriceChangeRequestParams(deltaPercentage: deltaPercentage)
    }
}

struct TokenPriceChangeRequestData {
    let params: TokenPriceChangeRequestParams

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenPriceChangeRequestData {
        let params = try TokenPriceChangeRequestParams.fromEventMessage(eventMessage)
        return TokenPriceChangeRequestData(params: params)
    }
}

struct TokenPriceChangeResponseData {
    let request: TokenPriceChangeRequestData
    let tokenDefinitionReference: ReplaceableEventReference
    let actions: [CommunityTokenActionEntity]

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenPriceChangeResponseData {
        let tagsByType = Dictionary(grouping: eventMessage.tags, by: { $0.first ?? "" })

        // Parse token definition reference from "a" tag
        guard let aTag = tagsByType[ReplaceableEventReference.tagName]?.first,
              aTag.count > 1 else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        guard let requestTag = tagsByType["request"]?.first,
              requestTag.count > 1,
              let requestJsonData = requestTag[1].data(using: .utf8),
              let requestJson = try? JSONSerialization.jsonObject(with: requestJsonData) as? [String: Any],
              let requestEventMessage = try? EventMessage.fromJson(requestJson) else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        let request = try TokenPriceChangeRequestData.fromEventMessage(requestEventMessage)
        let tokenDefinitionReference = ReplaceableEventReference.fromString(aTag[1])

        guard let contentData = eventMessage.content.data(using: .utf8),
              let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [[String: Any]] else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        let actions = try contentJson.map { actionJson in
            let actionEventMessage = try EventMessage.fromJson(actionJson)
            return try CommunityTokenActionEntity.fromEventMessage(actionEventMessage)
        }

        return TokenPriceChangeResponseData(
            request: request,
            tokenDefinitionReference: tokenDefinitionReference,
            actions: actions
        )
    }

    func computePriceChangePercent() -> Int {
        let fallback = request.params.deltaPercentage

        if actions.count < 2 {
            return fallback
        }

        guard let firstPrice = actions.first?.data.getTokenPrice(),
              let lastPrice = actions.last?.data.getTokenPrice(),
              firstPrice != 0 else {
            return fallback
        }

        return Int(((lastPrice - firstPrice) / firstPrice * 100).rounded())
    }
}

struct TokenPriceChangeResponseEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: TokenPriceChangeResponseData

    static let kind = 6176
    static let tagName = "a"

    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: TokenPriceChangeResponseData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenPriceChangeResponseEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let data = try TokenPriceChangeResponseData.fromEventMessage(eventMessage)

        return TokenPriceChangeResponseEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: eventMessage.pubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: data
        )
    }
}
