// SPDX-License-Identifier: ice License 1.0

import CryptoKit
import Foundation

struct EventMessage: Decodable {
    static let type = "EVENT"

    let id: String
    let pubkey: String
    let kind: Int
    let createdAt: Int
    let content: String
    let tags: [[String]]
    let sig: String?
    let subscriptionId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case pubkey
        case kind
        case createdAt = "created_at"
        case content
        case tags
        case sig
    }
    
    init(
        id: String,
        pubkey: String,
        createdAt: Int,
        kind: Int,
        tags: [[String]],
        content: String,
        sig: String?,
        subscriptionId: String? = nil
    ) {
        self.id = id
        self.pubkey = pubkey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        self.sig = sig
        self.subscriptionId = subscriptionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        pubkey = try container.decode(String.self, forKey: .pubkey)
        kind = try container.decode(Int.self, forKey: .kind)
        createdAt = try container.decode(Int.self, forKey: .createdAt)
        content = try container.decode(String.self, forKey: .content)
        tags = try container.decode([[String]].self, forKey: .tags)
        sig = try container.decodeIfPresent(String.self, forKey: .sig)
        subscriptionId = nil
    }

    func validate() -> Bool {
        let calculatedId = calculateEventId(
            publicKey: pubkey,
            createdAt: createdAt,
            kind: kind,
            tags: tags,
            content: content
        )

        if let calculatedId = calculatedId, id != calculatedId || sig == nil {
            return false
        }

        return SignatureVerifier.verify(
            publicKey: pubkey,
            message: id,
            signature: sig!
        )
    }

    func calculateEventId(
        publicKey: String,
        createdAt: Int,
        kind: Int,
        tags: [[String]],
        content: String
    ) -> String? {
        let eventData: [Any] = [
            0,
            publicKey,
            createdAt,
            kind,
            tags,
            content,
        ]

        guard
            let jsonData = try? JSONSerialization.data(
                withJSONObject: eventData,
                options: [.withoutEscapingSlashes]
            ),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }

        let hash = SHA256.hash(data: Data(jsonString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

extension EventMessage {
    enum ParsingError: Error {
        case invalidFormat
        case invalidType(String)
        case invalidPayload
        case invalidSubscriptionId
    }

    static func fromJson(_ json: [Any]) throws -> EventMessage {
        guard json.count == 2 || json.count == 3 else {
            throw ParsingError.invalidFormat
        }

        guard let type = json.first as? String else {
            throw ParsingError.invalidFormat
        }

        if type != EventMessage.type {
            throw ParsingError.invalidType(type)
        }

        let payloadIndex = json.count - 1

        guard let payload = json[payloadIndex] as? [String: Any] else {
            throw ParsingError.invalidPayload
        }

        var subscriptionId: String?
        if json.count == 3 {
            guard let decodedSubscriptionId = json[1] as? String else {
                throw ParsingError.invalidSubscriptionId
            }
            subscriptionId = decodedSubscriptionId
        }

        return try fromPayloadJson(payload, subscriptionId: subscriptionId)
    }

    static func fromJson(_ json: [String: Any]) throws -> EventMessage {
        return try fromPayloadJson(json)
    }

    static func fromPayloadJson(
        _ payloadJson: [String: Any],
        subscriptionId: String? = nil
    ) throws -> EventMessage {
        guard let id = payloadJson["id"] as? String,
              let pubkey = payloadJson["pubkey"] as? String,
              let createdAt = payloadJson["created_at"] as? Int,
              let kind = payloadJson["kind"] as? Int,
              let content = payloadJson["content"] as? String,
              let rawTags = payloadJson["tags"] as? [Any] else {
            throw ParsingError.invalidPayload
        }

        let tags = try rawTags.map { rawTag -> [String] in
            guard let tagItems = rawTag as? [Any] else {
                throw ParsingError.invalidPayload
            }

            return try tagItems.map { rawItem in
                guard let item = rawItem as? String else {
                    throw ParsingError.invalidPayload
                }
                return item
            }
        }

        let sig = payloadJson["sig"] as? String

        return EventMessage(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            kind: kind,
            tags: tags,
            content: content,
            sig: sig,
            subscriptionId: subscriptionId
        )
    }

    func masterPubkey() throws -> String {
        let masterPubkeyTag = tags.first { tag in tag.count > 1 && tag[0] == "b" }

        guard let masterPubkey = masterPubkeyTag?[1] else {
            throw EventMasterPubkeyNotFoundException(id)
        }

        return masterPubkey
    }
}
