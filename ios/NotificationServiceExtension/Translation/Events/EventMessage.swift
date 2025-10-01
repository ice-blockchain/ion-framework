// SPDX-License-Identifier: ice License 1.0

import CryptoKit
import Foundation

struct EventMessage: Decodable {
    let id: String
    let pubkey: String
    let kind: Int
    let createdAt: Int
    let content: String
    let tags: [[String]]
    let sig: String?

    enum CodingKeys: String, CodingKey {
        case id
        case pubkey
        case kind
        case createdAt = "created_at"
        case content
        case tags
        case sig
    }
    
    init(id: String, pubkey: String, createdAt: Int, kind: Int, tags: [[String]], content: String, sig: String?) {
        self.id = id
        self.pubkey = pubkey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        self.sig = sig
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
    func masterPubkey() throws -> String {
        let masterPubkeyTag = tags.first { tag in tag.count > 1 && tag[0] == "b" }

        guard let masterPubkey = masterPubkeyTag?[1] else {
            throw EventMasterPubkeyNotFoundException(id)
        }

        return masterPubkey
    }
}
