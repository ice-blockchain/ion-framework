// SPDX-License-Identifier: ice License 1.0

import Foundation

struct TokensGlobalStatRequestData {
    let input: TokenInput

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokensGlobalStatRequestData {
        let tagsByType = Dictionary(grouping: eventMessage.tags, by: { $0.first ?? "" })

        // Parse input from "i" tag
        guard let iTag = tagsByType[TokenInput.tagName]?.first else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        let input = try TokenInput.fromTag(iTag)

        return TokensGlobalStatRequestData(input: input)
    }
}

struct TokenGlobalStatResponseData {
    let request: TokensGlobalStatRequestData

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenGlobalStatResponseData {
        let tagsByType = Dictionary(grouping: eventMessage.tags, by: { $0.first ?? "" })

        // Parse request from "request" tag
        guard let requestTag = tagsByType["request"]?.first,
              requestTag.count > 1,
              let requestJsonString = requestTag[1].data(using: .utf8),
              let requestJson = try? JSONSerialization.jsonObject(with: requestJsonString) as? [String: Any],
              let requestEventMessage = try? EventMessage.fromJson(requestJson) else {
            throw IncorrectEventTagsException(eventId: eventMessage.id)
        }

        let request = try TokensGlobalStatRequestData.fromEventMessage(requestEventMessage)

        return TokenGlobalStatResponseData(request: request)
    }
}

struct TokenGlobalStatResponseEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: TokenGlobalStatResponseData

    static let kind = 6177

    init(
        id: String,
        pubkey: String,
        masterPubkey: String,
        signature: String,
        createdAt: Int,
        data: TokenGlobalStatResponseData
    ) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> TokenGlobalStatResponseEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()
        let data = try TokenGlobalStatResponseData.fromEventMessage(eventMessage)

        return TokenGlobalStatResponseEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: data
        )
    }
}
