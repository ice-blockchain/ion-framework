// SPDX-License-Identifier: ice License 1.0

import Foundation

struct TokenBuyingActivityResponseData {
    let tokenDefinition: CommunityTokenDefinitionEntity
    let tokenAction: CommunityTokenActionEntity

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenBuyingActivityResponseData {
        guard let contentData = eventMessage.content.data(using: .utf8),
              let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [Any] else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        var tokenDefinition: CommunityTokenDefinitionEntity?
        var tokenAction: CommunityTokenActionEntity?

        for item in contentJson {
            guard let eventJson = item as? [String: Any],
                  let nestedEvent = try? EventMessage.fromJson(eventJson) else {
                continue
            }

            if nestedEvent.kind == CommunityTokenDefinitionEntity.kind,
               tokenDefinition == nil {
                tokenDefinition = try? CommunityTokenDefinitionEntity.fromEventMessage(nestedEvent)
            }

            if nestedEvent.kind == CommunityTokenActionEntity.kind,
               tokenAction == nil {
                tokenAction = try? CommunityTokenActionEntity.fromEventMessage(nestedEvent)
            }

            if tokenDefinition != nil, tokenAction != nil {
                break
            }
        }

        guard let tokenDefinition,
              let tokenAction else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        return TokenBuyingActivityResponseData(
            tokenDefinition: tokenDefinition,
            tokenAction: tokenAction
        )
    }
}

struct TokenBuyingActivityResponseEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: TokenBuyingActivityResponseData

    static let kind = 6178

    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: TokenBuyingActivityResponseData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenBuyingActivityResponseEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let data = try TokenBuyingActivityResponseData.fromEventMessage(eventMessage)

        return TokenBuyingActivityResponseEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: eventMessage.pubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: data
        )
    }
}
