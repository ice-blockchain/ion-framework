// SPDX-License-Identifier: ice License 1.0

import Foundation

struct NotificationTranslationResult {
    let title: String
    let body: String
    let avatarFilePath: String?
    let attachmentFilePaths: String?
    let notificationType: PushNotificationType?
    let conversationId: String?
}

class NotificationTranslationService {
    private let appLocaleStorage: AppLocaleStorage
    private let keysStorage: KeysStorage
    private let translator: Translator<PushNotificationTranslations>
    private let encryptedMessageService: EncryptedMessageService?

    init(appLocaleStorage: AppLocaleStorage, keysStorage: KeysStorage) {
        self.appLocaleStorage = appLocaleStorage
        self.keysStorage = keysStorage

        let appLocale = appLocaleStorage.getAppLocale()
        let repository = TranslationsRepository<PushNotificationTranslations>(
            ionOrigin: Environment.ionOrigin,
            appLocaleStorage: appLocaleStorage,
            cacheMaxAge: TimeInterval(Environment.pushTranslationsCacheMinutes * 60)
        )

        self.translator = Translator<PushNotificationTranslations>(
            translationsRepository: repository,
            appLocale: appLocale
        )

        
        if let pubkey = keysStorage.getCurrentPubkey(), let currentIdentityKeyName = keysStorage.getCurrentIdentityKeyName() {
            self.encryptedMessageService = EncryptedMessageService(
                keychainService: KeychainService(currentIdentityKeyName: currentIdentityKeyName),
                pubkey: pubkey
            )
        } else {
            self.encryptedMessageService = nil
        }
    }

    func translate(_ pushPayload: [AnyHashable: Any]) async -> NotificationTranslationResult? {
        guard let currentPubkey = keysStorage.getCurrentPubkey() else {
            NSLog("[NSE] Current pubkey is nil")
            return nil
        }

        guard let data = await parsePayload(from: pushPayload) else {
            NSLog("[NSE] Failed to parse payload")
            return nil
        }

        if shouldSkipOwnGiftWrap(data: data, currentPubkey: currentPubkey) {
            NSLog("[NSE] Skipping own gift wrap notification")
            return nil
        }

        // Skip notifications from muted users or muted conversations
        if shouldSkipMutedNotification(data: data, currentPubkey: currentPubkey, keysStorage: keysStorage) {
            NSLog("[NSE] Skipping notification from muted user or conversation")
            return nil
        }

        // Skip notifications for self-interactions (e.g., quoting/reposting own content)
        if data.isSelfInteraction(currentPubkey: currentPubkey) {
            NSLog("[NSE] Skipping self-interaction notification")
            return nil
        }

        let dataIsValid = data.validate(currentPubkey: currentPubkey)

        if !dataIsValid {
            NSLog("[NSE] Data is invalid")
            return nil
        }

        guard let notificationType = data.getNotificationType(currentPubkey: currentPubkey, keysStorage: keysStorage) else {
            NSLog("[NSE] Notification type is nil")
            return nil
        }

        NSLog("[NSE] Notification type: \(notificationType)")

        guard let (title, body) = await getNotificationTranslation(for: notificationType) else {
            NSLog("[NSE] Notification translation is nil")
            return nil
        }

        let placeholders = data.placeholders(type: notificationType)
        
        let result = (
            title: replacePlaceholders(title, placeholders),
            body: replacePlaceholders(body, placeholders)
        )
        
        if hasPlaceholders(result.title) || hasPlaceholders(result.body) {
            NSLog("[NSE] Notification translation has placeholders")
            return nil
        }
        
        if result.title.isEmpty || result.body.isEmpty {
            NSLog("[NSE] Notification translation is empty")
            return nil
        }
        
        let media = await data.getMediaPlaceholders()

        return NotificationTranslationResult(
            title: result.title,
            body: result.body,
            avatarFilePath: media.avatar,
            attachmentFilePaths: media.attachment,
            notificationType: notificationType,
            conversationId: getConversationId(from: data.decryptedEvent)
        )
    }

    // MARK: - Private helper methods

    private func parsePayload(from pushPayload: [AnyHashable: Any]) async -> IonConnectPushDataPayload? {
        do {
            let payload = try await IonConnectPushDataPayload.fromJson(data: pushPayload) { event in

                let decryptedEvent = try? await self.encryptedMessageService?.decryptMessage(event)

                if let decryptedEvent = decryptedEvent {
                    NSLog("[NSE] Successfully decrypted event")
                } else {
                    NSLog("[NSE] Failed to decrypt event or decryption returned nil")
                }

                var metadata: UserMetadata? = nil

                if let decryptedEvent = decryptedEvent, let pubkey = try? decryptedEvent.masterPubkey() {
                    metadata = self.getUserMetadataFromDatabase(pubkey)
                } else {
                    NSLog("[NSE] Could not extract master pubkey from decrypted event")
                }

                return (event: decryptedEvent, metadata: metadata)
            }

            return payload
        } catch {
            NSLog("[NSE] Error parsing payload: \(error)")
            return nil
        }
    }

    private func getNotificationTranslation(for notificationType: PushNotificationType) async -> (title: String, body: String)?
    {
        let translation = await translator.translate { translations in
            switch notificationType {
            case .reply:
                return translations.reply
            case .replyArticle:
                return translations.replyArticle
            case .replyComment:
                return translations.replyComment
            case .mention:
                return translations.mention
            case .repost:
                return translations.repost
            case .repostArticle:
                return translations.repostArticle
            case .repostComment:
                return translations.repostComment
            case .quote:
                return translations.quote
            case .quoteArticle:
                return translations.quoteArticle
            case .quoteComment:
                return translations.quoteComment
            case .like:
                return translations.like
            case .likeArticle:
                return translations.likeArticle
            case .likeComment:
                return translations.likeComment
            case .likeStory:
                return translations.likeStory
            case .follower:
                return translations.follower
            case .paymentRequest:
                return translations.paymentRequest
            case .paymentReceived:
                return translations.paymentReceived
            case .chatDocumentMessage:
                return translations.chatDocumentMessage
            case .chatEmojiMessage:
                return translations.chatEmojiMessage
            case .chatPhotoMessage:
                return translations.chatPhotoMessage
            case .chatProfileMessage:
                return translations.chatProfileMessage
            case .chatReaction:
                return translations.chatReaction
            case .chatSharePostMessage:
                return translations.chatSharePostMessage
            case .chatShareArticleMessage:
                return translations.chatShareArticleMessage
            case .chatShareStoryMessage:
                return translations.chatShareStoryMessage
            case .chatSharedStoryReplyMessage:
                return translations.chatSharedStoryReplyMessage
            case .chatTextMessage:
                return translations.chatTextMessage
            case .chatVideoMessage:
                return translations.chatVideoMessage
            case .chatVoiceMessage:
                return translations.chatVoiceMessage
            case .chatFirstContactMessage:
                return translations.chatFirstContactMessage
            case .chatGifMessage:
                return translations.chatGifMessage
            case .chatMultiGifMessage:
                return translations.chatMultiGifMessage
            case .chatMultiMediaMessage:
                return translations.chatMultiMediaMessage
            case .chatMultiPhotoMessage:
                return translations.chatMultiPhotoMessage
            case .chatMultiVideoMessage:
                return translations.chatMultiVideoMessage
            case .chatPaymentRequestMessage:
                return translations.chatPaymentRequestMessage
            case .chatPaymentReceivedMessage:
                return translations.chatPaymentReceivedMessage
            }
        }

        guard let translation = translation,
            let title = translation.title,
            let body = translation.body
        else {
            NSLog("[NSE] Translation is nil")
            return nil
        }

        return (title: title, body: body)

    }
    /// Replaces placeholders in the format `{{key}}` within the input string
    /// using corresponding values from the placeholders map.
    private func replacePlaceholders(_ input: String, _ placeholders: [String: String]) -> String {
        let regex = try! NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}", options: [])
        let nsString = input as NSString
        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length))

        var result = input

        for match in matches.reversed() {
            let fullMatch = nsString.substring(with: match.range)
            let keyRange = match.range(at: 1)

            if keyRange.location != NSNotFound {
                let key = nsString.substring(with: keyRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let replacement = placeholders[key] ?? fullMatch

                let mutableResult = NSMutableString(string: result)
                mutableResult.replaceCharacters(in: match.range, with: replacement)
                result = mutableResult as String
            }
        }

        return result
    }

    private func hasPlaceholders(_ input: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}", options: [])
        return regex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: (input as NSString).length)) != nil
    }
    
    private func getUserMetadataFromDatabase(_ pubkey: String) -> UserMetadata? {
        let cacheDB = IonConnectCacheDatabase(keysStorage: keysStorage)
        guard cacheDB.openDatabase() else {
            NSLog("[NSE] Failed to open ion_connect_cache database for quote notification type")
            return nil
        }
        
        defer { cacheDB.closeDatabase() }
        
        let eventReference = ReplaceableEventReference(masterPubkey: pubkey, kind: UserMetadataEntity.kind)
        let eventReferenceKey = eventReference.toString()
        
        guard let userMetadata: UserMetadataEntity = cacheDB.getEntity(for: eventReferenceKey) else {
            return nil
        }
        
        return userMetadata.data
    }
    
    private func getConversationId(from event: EventMessage?) -> String? {
        guard let event = event else { return nil }
        
        // Look for "h" tag in the tags array
        for tag in event.tags {
            if tag.count >= 2 && tag[0] == "h" {
                return tag[1]
            }
        }
        
        return nil
    }
    
    /// Check if notification should be skipped because user/conversation is muted
    private func shouldSkipMutedNotification(data: IonConnectPushDataPayload, currentPubkey: String, keysStorage: KeysStorage) -> Bool {
        guard data.event.kind == IonConnectGiftWrapEntity.kind else {
            return false
        }
        
        guard let decryptedEvent = data.decryptedEvent else {
            return false
        }
        
        guard let senderPubkey = try? decryptedEvent.masterPubkey() else { return false }
        
        let cacheDB = IonConnectCacheDatabase(keysStorage: keysStorage)
        if cacheDB.openDatabase() {
            defer { cacheDB.closeDatabase() }
            let mutedUsers = cacheDB.getMutedUsers()
            if mutedUsers.contains(senderPubkey) {
                NSLog("[NSE] Sender is muted: \(senderPubkey)")
                return true
            }
        }
        
        let chatDB = ChatDatabase(keysStorage: keysStorage)
        if chatDB.openDatabase() {
            defer { chatDB.closeDatabase() }
            let mutedConversationIds = chatDB.getMutedConversationIds(currentUserMasterPubkey: currentPubkey)
            
            let sortedPubkeys = [senderPubkey, currentPubkey].sorted()
            let conversationId = sortedPubkeys.joined(separator: "")
            
            if mutedConversationIds.contains(conversationId) {
                NSLog("[NSE] Conversation is muted: \(conversationId)")
                return true
            }
        }
        
        return false
    }
    
    /// Check if the gift wrap notification should be skipped because it's from the current user
    private func shouldSkipOwnGiftWrap(data: IonConnectPushDataPayload, currentPubkey: String) -> Bool {
        guard data.event.kind == IonConnectGiftWrapEntity.kind else {
            return false
        }
        
        guard let decryptedEvent = data.decryptedEvent else {
            return false
        }
        
        guard let rumorMasterPubkey = try? decryptedEvent.masterPubkey() else {
            return false
        }
        
        return rumorMasterPubkey == currentPubkey
    }
}

