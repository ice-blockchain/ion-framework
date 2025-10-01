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
        if let storage = try? SharedStorage() {
            let KeysStorage = KeysStorage(storage: storage)
            let walletsDB = WalletsDatabase(keysStorage: KeysStorage)
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
                NSLog("[NSE] Error decompressing data: \(error)")
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

    func getNotificationType(currentPubkey: String, keysStorage: KeysStorage) -> PushNotificationType? {
        guard let entity = mainEntity else {
            return nil
        }

        if entity is GenericRepostEntity || entity is RepostEntity {
            return getRepostNotificationType(entity: entity, keysStorage: keysStorage)
        } else if (entity as? ModifiablePostEntity)?.data.quotedEvent != nil ||
                  (entity as? PostEntity)?.data.quotedEvent != nil {
            return getQuoteNotificationType(entity: entity, keysStorage: keysStorage)
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
            }
                
            return getReplyNotificationType(entity: entity, keysStorage: keysStorage)
        } else if let reactionEntity = entity as? ReactionEntity {
            return getLikeNotificationType(entity: reactionEntity, keysStorage: keysStorage)
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
                
                // Check if this is a first contact message (no user metadata)
                if decryptedPlaceholders == nil {
                    return .chatFirstContactMessage
                }

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
                    case .requestFunds:
                        return .chatPaymentRequestMessage
                    case .moneySent:
                        return .chatPaymentReceivedMessage
                    case .sharedPost:
                        return getSharedPostNotificationType(message: message)
                    case .visualMedia:
                        return getVisualMediaNotificationType(message: message)
                    }
                } catch {
                    NSLog("[NSE] Error parsing decrypted message: \(error)")
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
                NSLog("[NSE] Conversion failed: \(error)")
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
                NSLog("[NSE] Error parsing delegation entity: \(error)")
                return false
            }
        }
    }

    private func getLikeNotificationType(entity: ReactionEntity, keysStorage: KeysStorage) -> PushNotificationType {
        let cacheKey = entity.data.eventReference.toString()
        
        let cacheDB = IonConnectCacheDatabase(keysStorage: keysStorage)
        guard cacheDB.openDatabase() else {
            NSLog("[NSE] Failed to open ion_connect_cache database for like notification type")
            return .like
        }
        defer { cacheDB.closeDatabase() }
        
        guard let relatedEntity = cacheDB.getRelatedEntity(eventReference: cacheKey) else {
            NSLog("[NSE] No related entity found in cache for: \(cacheKey)")
            return .like
        }
        
        // Check if it's a story (has expiration)
        if let modifiablePost = relatedEntity as? ModifiablePostEntity {
            if modifiablePost.data.expiration != nil {
                return .likeStory
            }
            if modifiablePost.data.parentEvent != nil {
                return .likeComment
            }
            return .like
        }
        
        // Check if it's an article
        if relatedEntity is ArticleEntity {
            return .likeArticle
        }
                
        return .like
    }

    private func getRepostNotificationType(entity: IonConnectEntity, keysStorage: KeysStorage) -> PushNotificationType {
        // Extract event reference from the repost entity
        let eventReference: EventReference
        if let genericRepost = entity as? GenericRepostEntity {
            eventReference = genericRepost.data.eventReference
        } else if let repost = entity as? RepostEntity {
            eventReference = repost.data.eventReference
        } else {
            return .repost
        }
        
        let cacheKey = eventReference.toString()
        
        let cacheDB = IonConnectCacheDatabase(keysStorage: keysStorage)
        guard cacheDB.openDatabase() else {
            NSLog("[NSE] Failed to open ion_connect_cache database for repost notification type")
            return .repost
        }
        defer { cacheDB.closeDatabase() }
        
        guard let repostedEntity = cacheDB.getRelatedEntity(eventReference: cacheKey) else {
            NSLog("[NSE] No related entity found in cache for: \(cacheKey)")
            return .repost
        }
        
        // Check if it's an article
        if repostedEntity is ArticleEntity {
            return .repostArticle
        }
        
        // Check if it's a comment (post with parent event)
        if let modifiablePost = repostedEntity as? ModifiablePostEntity {
            if modifiablePost.data.parentEvent != nil {
                return .repostComment
            }
        } else if let post = repostedEntity as? PostEntity {
            if post.data.parentEvent != nil {
                return .repostComment
            }
        }
        
        return .repost
    }
    
    private func getQuoteNotificationType(entity: IonConnectEntity, keysStorage: KeysStorage) -> PushNotificationType {
        // Extract quoted event reference from the entity
        let quotedEventRef: EventReference?
        if let modifiablePost = entity as? ModifiablePostEntity {
            quotedEventRef = modifiablePost.data.quotedEvent?.eventReference
        } else if let post = entity as? PostEntity {
            quotedEventRef = post.data.quotedEvent?.eventReference
        } else {
            return .quote
        }
        
        guard let eventReference = quotedEventRef else {
            return .quote
        }
        
        let cacheKey = eventReference.toString()
        
        let cacheDB = IonConnectCacheDatabase(keysStorage: keysStorage)
        guard cacheDB.openDatabase() else {
            NSLog("[NSE] Failed to open ion_connect_cache database for quote notification type")
            return .quote
        }
        defer { cacheDB.closeDatabase() }
        
        guard let quotedEntity = cacheDB.getRelatedEntity(eventReference: cacheKey) else {
            NSLog("[NSE] No related entity found in cache for: \(cacheKey)")
            return .quote
        }
        
        // Check if it's an article
        if quotedEntity is ArticleEntity {
            return .quoteArticle
        }
        
        // Check if it's a comment (post with parent event)
        if let modifiablePost = quotedEntity as? ModifiablePostEntity {
            if modifiablePost.data.parentEvent != nil {
                return .quoteComment
            }
        } else if let post = quotedEntity as? PostEntity {
            if post.data.parentEvent != nil {
                return .quoteComment
            }
        }
        
        return .quote
    }
    
    private func getReplyNotificationType(entity: IonConnectEntity, keysStorage: KeysStorage) -> PushNotificationType {
        // Extract parent event reference string from the entity
        let parentEventRefString: String?
        if let modifiablePost = entity as? ModifiablePostEntity {
            parentEventRefString = modifiablePost.data.parentEvent?.eventReference
        } else if let post = entity as? PostEntity {
            parentEventRefString = post.data.parentEvent?.eventReference
        } else {
            return .reply
        }
        
        guard let cacheKey = parentEventRefString else {
            return .reply
        }
        
        let cacheDB = IonConnectCacheDatabase(keysStorage: keysStorage)
        guard cacheDB.openDatabase() else {
            NSLog("[NSE] Failed to open ion_connect_cache database for reply notification type")
            return .reply
        }
        defer { cacheDB.closeDatabase() }
        
        guard let parentEntity = cacheDB.getRelatedEntity(eventReference: cacheKey) else {
            NSLog("[NSE] No related entity found in cache for: \(cacheKey)")
            return .reply
        }
        
        // Check if it's an article
        if parentEntity is ArticleEntity {
            return .replyArticle
        }
        
        // Check if it's a comment (post with parent event)
        if let modifiablePost = parentEntity as? ModifiablePostEntity {
            if modifiablePost.data.parentEvent != nil {
                return .replyComment
            }
        } else if let post = parentEntity as? PostEntity {
            if post.data.parentEvent != nil {
                return .replyComment
            }
        }
        
        return .reply
    }
    
    private func getSharedPostNotificationType(message: ReplaceablePrivateDirectMessageEntity) -> PushNotificationType {
        // If message has content, it's a reply to a shared story
        if !message.data.content.isEmpty {
            return .chatSharedStoryReplyMessage
        }
        
        // Check the quoted event kind to determine the type
        if let quotedEventKind = message.data.quotedEventKind,
           let kind = Int(quotedEventKind) {
            switch kind {
            case ModifiablePostEntity.kind, PostEntity.kind:
                return .chatSharePostMessage
            case ModifiablePostEntity.storyKind:
                return .chatShareStoryMessage
            case ArticleEntity.kind:
                return .chatShareArticleMessage
            default:
                return .chatSharePostMessage
            }
        }
        
        return .chatSharePostMessage
    }
    
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
    case replyArticle
    case replyComment
    case mention
    case repost
    case repostArticle
    case repostComment
    case quote
    case quoteArticle
    case quoteComment
    case like
    case likeArticle
    case likeComment
    case likeStory
    case follower
    case paymentRequest
    case paymentReceived
    case chatDocumentMessage
    case chatEmojiMessage
    case chatPhotoMessage
    case chatProfileMessage
    case chatReaction
    case chatSharePostMessage
    case chatShareArticleMessage
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
             .chatShareArticleMessage,
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
