// SPDX-License-Identifier: ice License 1.0

import Foundation

struct UserMetadataEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: UserMetadata

    static let kind = 0

    static func fromEventMessage(_ eventMessage: EventMessage) throws
        -> UserMetadataEntity
    {
        guard eventMessage.kind == kind else {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        return UserMetadataEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: try eventMessage.masterPubkey(),
            signature: eventMessage.sig!,
            createdAt: eventMessage.createdAt,
            data: UserMetadata.fromEventMessage(eventMessage)
        )
    }
}

struct UserMetadata {
    let name: String
    let displayName: String
    let picture: String?

    static func fromEventMessage(_ eventMessage: EventMessage) -> UserMetadata {
        let contentData = eventMessage.content.data(using: .utf8)

        let userData = try! JSONDecoder().decode(
            UserDataEventMessageContent.self,
            from: contentData!
        )

        return UserMetadata(
            name: userData.name ?? "",
            displayName: userData.displayName ?? "",
            picture: userData.picture
        )
    }
}

struct UserDataEventMessageContent: Codable {
    let name: String?
    let displayName: String?
    let picture: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case picture
    }
}
