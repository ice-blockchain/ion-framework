// SPDX-License-Identifier: ice License 1.0

import Foundation

struct TransactionData {
    let coinAmount: String
    let coinSymbol: String
}

class IonConnectPushDataPayload: Decodable {
    let compression: String?
    let event: EventMessage
    let decryptedEvent: EventMessage?
    let relevantEvents: [EventMessage]
    let decryptedPlaceholders: [String: String]?

    enum CodingKeys: String, CodingKey {
        case compression
        case event
        case relevantEvents = "relevant_events"
    }

    private static func getCoinData(assetId: String) -> CoinDBInfo? {
        if let storage = try? SharedStorageService() {
            let walletsDB = WalletsDatabaseManager(storage: storage)
            if walletsDB.openDatabase() {
                defer { walletsDB.closeDatabase() }
                return walletsDB.getCoinData(assetId: assetId)
            }
        }
        return nil
    }

    private static func buildTransactionData(from decryptedEvent: EventMessage?) -> TransactionData? {
        guard let dec = decryptedEvent else { return nil }

        if let wa = try? WalletAssetEntity.fromEventMessage(dec),
           let assetId = wa.data.assetId,
           let coin = getCoinData(assetId: assetId)
        {
            let raw = wa.data.amount
            if !raw.isEmpty {
                let normalized = CryptoAmountFormatter.parse(raw, decimals: coin.decimals)
                let formatted  = CryptoAmountFormatter.format(normalized)
                return TransactionData(coinAmount: formatted, coinSymbol: coin.abbreviation)
            }
        }

        if let fr = try? FundsRequestEntity.fromEventMessage(dec),
           let assetId = fr.data.assetId,
           let coin = getCoinData(assetId: assetId)
        {
            let raw = fr.data.amount
            if !raw.isEmpty {
                return TransactionData(coinAmount: raw, coinSymbol: coin.abbreviation)
            }
        }

        return nil
    }

    static func fromJson(
        data: [AnyHashable: Any],
        decryptEvent: @escaping (EventMessage) async throws -> (event: EventMessage?, metadata: UserMetadata?)?
    ) async throws -> IonConnectPushDataPayload {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let payload = try JSONDecoder().decode(IonConnectPushDataPayload.self, from: jsonData)

        // Check if we need to decrypt the event
        if payload.event.kind == IonConnectGiftWrapEntity.kind {
            let result = try await decryptEvent(payload.event)

            // Create placeholders dictionary from metadata if available
            var placeholders: [String: String] = [:]
            if let metadata = result?.metadata {
                placeholders["username"] = metadata.name
                placeholders["displayName"] = metadata.displayName
                if let picture = metadata.picture {
                    placeholders["picture"] = picture
                }
            }

            let txData = IonConnectPushDataPayload.buildTransactionData(from: result?.event)
            if let tx = txData {
                placeholders["coinAmount"] = tx.coinAmount
                placeholders["coinSymbol"] = tx.coinSymbol
            }

            return IonConnectPushDataPayload(
                compression: payload.compression,
                event: payload.event,
                decryptedEvent: result?.event,
                relevantEvents: payload.relevantEvents,
                decryptedPlaceholders: placeholders.isEmpty ? nil : placeholders
            )
        }

        return payload
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        compression = try container.decodeIfPresent(
            String.self,
            forKey: .compression
        )

        let eventString = try container.decode(String.self, forKey: .event)
        let relevantEventsString = try container.decodeIfPresent(String.self, forKey: .relevantEvents) ?? ""

        if let compression = compression, compression == "zlib" {
            do {
                let eventData = try Decompressor.decompress(eventString)
                event = try JSONDecoder().decode(EventMessage.self, from: eventData)

                if !relevantEventsString.isEmpty {
                    let relevantEventsData = try Decompressor.decompress(relevantEventsString)
                    relevantEvents = try JSONDecoder().decode([EventMessage].self, from: relevantEventsData)
                } else {
                    relevantEvents = []
                }
            } catch {
                NSLog("Error decompressing data: \(error)")
                throw error
            }
        } else {
            guard let eventData = eventString.data(using: .utf8) else {
                throw DecompressionError.jsonDataConversionFailed
            }
            event = try JSONDecoder().decode(EventMessage.self, from: eventData)

            if !relevantEventsString.isEmpty,
                let relevantEventsData = relevantEventsString.data(using: .utf8)
            {
                relevantEvents = try JSONDecoder().decode(
                    [EventMessage].self,
                    from: relevantEventsData
                )
            } else {
                relevantEvents = []
            }
        }

        self.decryptedEvent = nil
        self.decryptedPlaceholders = nil
    }

    /// Internal initializer for creating a payload with a decrypted event
    internal init(
        compression: String?,
        event: EventMessage,
        decryptedEvent: EventMessage?,
        relevantEvents: [EventMessage],
        decryptedPlaceholders: [String: String]? = nil
    ) {
        self.compression = compression
        self.event = event
        self.decryptedEvent = decryptedEvent
        self.relevantEvents = relevantEvents
        self.decryptedPlaceholders = decryptedPlaceholders
    }

    var mainEntity: IonConnectEntity? {
        return try? EventParser.parse(event)
    }

    func getNotificationType(currentPubkey: String) -> PushNotificationType? {
        guard let entity = mainEntity else {
            return nil
        }

        if entity is GenericRepostEntity || entity is RepostEntity {
            return .repost
        } else if (entity as? ModifiablePostEntity)?.data.quotedEvent != nil ||
                  (entity as? PostEntity)?.data.quotedEvent != nil {
            return .quote
        } else if entity is ModifiablePostEntity || entity is PostEntity {
            let currentUserMention = ReplaceableEventReference(
                masterPubkey: currentPubkey,
                kind: UserMetadataEntity.kind
            ).encode()

            let content: String? = {
                switch entity {
                case let e as ModifiablePostEntity:
                    return e.data.content
                case let e as PostEntity:
                    return e.data.content
                default:
                    return nil
                }
            }()

            if let content = content, content.contains(currentUserMention) {
                return .mention
            } else {
                return .reply
            }
        } else if entity is ReactionEntity {
            return .like
        } else if entity is FollowListEntity {
            return .follower
        } else if let entity = entity as? IonConnectGiftWrapEntity {
            if entity.data.kinds.contains(String(ReactionEntity.kind)) {
                return .chatReaction
            } else if entity.data.kinds.contains(String(FundsRequestEntity.kind)) {
                return .paymentRequest
            } else if entity.data.kinds.contains(String(WalletAssetEntity.kind)) {
                return .paymentReceived
            } else if entity.data.kinds.contains(String(ReplaceablePrivateDirectMessageEntity.kind)) {
                // If we don't have a decrypted event, we can't determine the message type
                guard let decryptedEvent = decryptedEvent else { return nil }

                do {
                    let message = try ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent)

                    switch message.data.messageType {
                    case .audio:
                        return .chatVoiceMessage
                    case .document:
                        return .chatDocumentMessage
                    case .text:
                        return .chatTextMessage
                    case .emoji:
                        return .chatEmojiMessage
                    case .profile:
                        return .chatProfileMessage
                    case .sharedPost:
                        return .chatSharePostMessage
                    case .requestFunds:
                        return .chatPaymentRequestMessage
                    case .moneySent:
                        return .chatPaymentReceivedMessage
                    case .visualMedia:
                        return getVisualMediaNotificationType(message: message)
                    }
                } catch {
                    NSLog("Error parsing decrypted message: \(error)")
                    return nil
                }
            }
        }

        return nil
    }

    func placeholders(type: PushNotificationType) -> [String: String] {
        guard let masterPubkey = mainEntity?.masterPubkey else {
            return [:]
        }

        var data = decryptedPlaceholders ?? [:]

        let mainEntityUserMetadata = getUserMetadata(pubkey: masterPubkey)
        if let mainEntityUserMetadata = mainEntityUserMetadata {
            data["username"] = mainEntityUserMetadata.data.name
            data["displayName"] = mainEntityUserMetadata.data.displayName
        }

        if let decryptedEvent = decryptedEvent {
            data["messageContent"] = decryptedEvent.content
            data["reactionContent"] = decryptedEvent.content

            if let entity = try? IonConnectGiftWrapEntity.fromEventMessage(event),
                entity.data.kinds.contains(String(ReplaceablePrivateDirectMessageEntity.kind))
            {
                if let message = try? ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent) {

                    if type == PushNotificationType.chatMultiGifMessage || type == PushNotificationType.chatMultiPhotoMessage {
                        let media = message.data.media.filter { $0.thumb == nil }
                        data["fileCount"] = String(media.count)
                    }

                    if type == PushNotificationType.chatMultiVideoMessage {
                        let videoItems = message.data.media.filter { $0.mediaType == .video && $0.thumb == nil }
                        data["fileCount"] = String(videoItems.count)
                    }

                    if type == PushNotificationType.chatDocumentMessage, let media = message.data.media.first {
                        data["documentExt"] = FileTypeMapper.getFileType(mimeType: media.originalMimeType)
                    }
                }
            }
        }

        return data
    }

    func getMediaPlaceholders() async -> (avatar: String?, attachment: String?) {
        guard let masterPubkey = mainEntity?.masterPubkey else {
            return (avatar: nil, attachment: nil)
        }

        var avatarUrl: String?
        var attachmentUrl: String?

        let mainEntityUserMetadata = getUserMetadata(pubkey: masterPubkey)
        if let mainEntityUserMetadata = mainEntityUserMetadata {
            avatarUrl = mainEntityUserMetadata.data.picture
        } else {
            if let decryptedPlaceholders = decryptedPlaceholders {
                avatarUrl = decryptedPlaceholders["picture"]
            }
        }

        if let decryptedEvent = decryptedEvent {
            if let entity = try? IonConnectGiftWrapEntity.fromEventMessage(event),
                entity.data.kinds.contains(String(ReplaceablePrivateDirectMessageEntity.kind))
            {
                if let message = try? ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent) {
                    let image = message.data.visualMedias.first(where: { mediaItem in
                        return mediaItem.mediaType == .image
                    })

                    attachmentUrl = image?.thumb ?? image?.url
                }
            }
        }

        var avatarFilePath: String?

        if let avatarUrl = avatarUrl {
            let avatarOutputFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("user_avatar.jpg")
            do {
                let outputFileURL = try await ImageConverter().convertWebPToJPEG(
                    webpURLString: avatarUrl,
                    outputJPEGURL: avatarOutputFilePath
                )
                avatarFilePath = outputFileURL.path
            } catch {
                NSLog("Conversion failed: \(error)")
            }

        }

        return (avatar: avatarFilePath, attachment: attachmentUrl)
    }

    func validate(currentPubkey: String) -> Bool {
        return checkEventsSignatures()
            && checkMainEventRelevant(currentPubkey: currentPubkey)
            && checkRequiredRelevantEvents()
    }

    // MARK: - Private Helper Methods

    private func checkEventsSignatures() -> Bool {
        let mainEventValid = event.validate()
        let relevantEventsValid = relevantEvents.allSatisfy { $0.validate() }

        return mainEventValid && relevantEventsValid
    }

    private func checkMainEventRelevant(currentPubkey: String) -> Bool {
        guard let entity = mainEntity else {
            return false
        }

        if let modifiablePost = entity as? ModifiablePostEntity {
            let event = modifiablePost.data.quotedEvent
            
            let isInRelatedPubkeys = modifiablePost.data.relatedPubkeys.contains { pubkey in
                return pubkey.value == currentPubkey
            }
            
            let isPostAuthor = event != nil && event!.eventReference.masterPubkey == currentPubkey
            
            return isInRelatedPubkeys || isPostAuthor
        } else if let post = entity as? PostEntity {
            let event = post.data.quotedEvent
            
            let isInRelatedPubkeys = post.data.relatedPubkeys.contains { pubkey in
                return pubkey.value == currentPubkey
            }
            
            let isPostAuthor = event != nil && event!.eventReference.masterPubkey == currentPubkey
            
            return isInRelatedPubkeys || isPostAuthor
        } else if let genericRepost = entity as? GenericRepostEntity {
            return genericRepost.data.eventReference.masterPubkey == currentPubkey
        } else if let repost = entity as? RepostEntity {
            return repost.data.eventReference.masterPubkey == currentPubkey
        } else if let reaction = entity as? ReactionEntity {
            return reaction.data.eventReference.masterPubkey == currentPubkey
        } else if let followList = entity as? FollowListEntity {
            return followList.pubkeys.last == currentPubkey
        } else if let giftWrap = entity as? IonConnectGiftWrapEntity {
            return giftWrap.data.relatedPubkeys.contains { pubkey in
                return pubkey.value == currentPubkey
            }
        }

        return false
    }

    private func checkRequiredRelevantEvents() -> Bool {
        if event.kind == IonConnectGiftWrapEntity.kind {
            return true
        } else {
            // For all events except 1059 we need to check if delegation is present
            // in the relevant events and the main event valid for it
            let delegationEvent = relevantEvents.first { event in
                return event.kind == UserDelegationEntity.kind
            }

            guard let delegationEvent = delegationEvent else {
                return false
            }

            do {
                let delegationEntity =
                    try UserDelegationEntity.fromEventMessage(delegationEvent)
                return delegationEntity.data.validate(event)
            } catch {
                NSLog("Error parsing delegation entity: \(error)")
                return false
            }
        }
    }

    /// Determines the notification type for visual media messages based on media content
    /// - Parameter message: The private direct message entity containing visual media
    /// - Returns: The appropriate push notification type based on media content
    private func getVisualMediaNotificationType(message: ReplaceablePrivateDirectMessageEntity) -> PushNotificationType {
        let mediaItems = message.data.media

        if let mediaType = mediaItems.first?.mediaType, mediaItems.count == 1 {
            if mediaType == .image { return .chatPhotoMessage }
            if mediaType == .gif { return .chatGifMessage }
            if mediaType == .video { return .chatVideoMessage }
        } else {
            if mediaItems.allSatisfy({ $0.mediaType == .image }) { return .chatMultiPhotoMessage }
            if mediaItems.allSatisfy({ $0.mediaType == .gif }) { return .chatMultiGifMessage }

            let videoItems = mediaItems.filter { $0.mediaType == .video }
            let thumbItems = mediaItems.filter { $0.mediaType == .image || $0.mediaType == .gif }
            if videoItems.count == thumbItems.count {
                return videoItems.count == 1 ? .chatVideoMessage : .chatMultiVideoMessage
            }
        }

        return .chatMultiMediaMessage
    }

    private func getUserMetadata(pubkey: String) -> UserMetadataEntity? {
        let delegationEvent = relevantEvents.first { event in
            return event.kind == UserDelegationEntity.kind
                && event.pubkey == pubkey
        }

        guard let delegationEvent = delegationEvent else { return nil }

        let delegationEntity = try! UserDelegationEntity.fromEventMessage(
            delegationEvent
        )

        for event in relevantEvents {
            if event.kind == UserMetadataEntity.kind
                && delegationEntity.data.validate(event)
            {
                do {
                    let userMetadataEntity =
                        try UserMetadataEntity.fromEventMessage(event)
                    if userMetadataEntity.masterPubkey
                        == delegationEntity.pubkey
                    {
                        return userMetadataEntity
                    }
                } catch {
                    continue
                }
            }
        }

        return nil
    }
}

enum PushNotificationType: String, Decodable {
    case reply
    case mention
    case repost
    case quote
    case like
    case follower
    case paymentRequest
    case paymentReceived
    case chatDocumentMessage
    case chatEmojiMessage
    case chatPhotoMessage
    case chatProfileMessage
    case chatReaction
    case chatSharePostMessage
    case chatShareStoryMessage
    case chatSharedStoryReplyMessage
    case chatTextMessage
    case chatVideoMessage
    case chatVoiceMessage
    case chatFirstContactMessage
    case chatGifMessage
    case chatMultiGifMessage
    case chatMultiMediaMessage
    case chatMultiPhotoMessage
    case chatMultiVideoMessage
    case chatPaymentRequestMessage
    case chatPaymentReceivedMessage
    
    var isChat: Bool {
        switch self {
        case .chatDocumentMessage,
             .chatEmojiMessage,
             .chatPhotoMessage,
             .chatProfileMessage,
             .chatReaction,
             .chatSharePostMessage,
             .chatShareStoryMessage,
             .chatSharedStoryReplyMessage,
             .chatTextMessage,
             .chatVideoMessage,
             .chatVoiceMessage,
             .chatFirstContactMessage,
             .chatGifMessage,
             .chatMultiGifMessage,
             .chatMultiMediaMessage,
             .chatMultiPhotoMessage,
             .chatMultiVideoMessage,
             .chatPaymentRequestMessage,
             .chatPaymentReceivedMessage:
            return true
        default:
            return false
        }
    }
}
