// SPDX-License-Identifier: ice License 1.0

import Foundation

class EventParser {
    static func parse(_ eventMessage: EventMessage) throws -> IonConnectEntity {
        switch eventMessage.kind {
        case UserMetadataEntity.kind:
            return try UserMetadataEntity.fromEventMessage(eventMessage)
        case PostEntity.kind:
            return try PostEntity.fromEventMessage(eventMessage)
        case FollowListEntity.kind:
            return try FollowListEntity.fromEventMessage(eventMessage)
        case RepostEntity.kind:
            return try RepostEntity.fromEventMessage(eventMessage)
        case ReactionEntity.kind:
            return try ReactionEntity.fromEventMessage(eventMessage)
        case GenericRepostEntity.kind:
            return try GenericRepostEntity.fromEventMessage(eventMessage)
        case UserDelegationEntity.kind:
            return try UserDelegationEntity.fromEventMessage(eventMessage)
        case IonConnectGiftWrapEntity.kind:
            return try IonConnectGiftWrapEntity.fromEventMessage(eventMessage)
        case ModifiablePostEntity.kind:
            return try ModifiablePostEntity.fromEventMessage(eventMessage)
        case ArticleEntity.kind:
            return try ArticleEntity.fromEventMessage(eventMessage)
        case ReplaceablePrivateDirectMessageEntity.kind:
            return try ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage)
        case FundsRequestEntity.kind:
            return try FundsRequestEntity.fromEventMessage(eventMessage)
        case WalletAssetEntity.kind:
            return try WalletAssetEntity.fromEventMessage(eventMessage)
        default:
            throw UnknownEventException(eventId: eventMessage.id, kind: eventMessage.kind)
        }
    }
}
