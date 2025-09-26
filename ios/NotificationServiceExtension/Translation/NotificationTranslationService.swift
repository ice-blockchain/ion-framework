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
            return nil
        }

        guard let data = await parsePayload(from: pushPayload) else {
            return nil
        }

        let dataIsValid = data.validate(currentPubkey: currentPubkey)

        if !dataIsValid {
            return nil
        }

        guard let notificationType = data.getNotificationType(currentPubkey: currentPubkey) else {
            return nil
        }

        guard let (title, body) = await getNotificationTranslation(for: notificationType) else {
            return nil
        }

        let placeholders = data.placeholders(type: notificationType)
        
        let result = (
            title: replacePlaceholders(title, placeholders),
            body: replacePlaceholders(body, placeholders)
        )
        
        if hasPlaceholders(result.title) || hasPlaceholders(result.body) {
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
                    NSLog("Successfully decrypted event: \(decryptedEvent.id)")
                } else {
                    NSLog("Failed to decrypt event or decryption returned nil")
                }

                var metadata: UserMetadata? = nil

                if let decryptedEvent = decryptedEvent, let pubkey = try? decryptedEvent.masterPubkey() {
                    metadata = self.getUserMetadataFromDatabase(pubkey)
                } else {
                    NSLog("Could not extract master pubkey from decrypted event")
                }

                return (event: decryptedEvent, metadata: metadata)
            }

            return payload
        } catch {
            NSLog("Error parsing payload: \(error)")
            return nil
        }
    }

    private func getNotificationTranslation(for notificationType: PushNotificationType) async -> (title: String, body: String)?
    {
        let translation = await translator.translate { translations in
            switch notificationType {
            case .reply:
                return translations.reply
            case .mention:
                return translations.mention
            case .repost:
                return translations.repost
            case .quote:
                return translations.quote
            case .like:
                return translations.like
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
            let chatUsermetadataDB = ChatUserMetadataDatabase(keysStorage: keysStorage)
            if chatUsermetadataDB.openDatabase() {
                defer { chatUsermetadataDB.closeDatabase() }
                return chatUsermetadataDB.getUserMetadataFromDatabase(pubkey: pubkey)
            }
        
        return nil
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
}
