// SPDX-License-Identifier: ice License 1.0

import Foundation

struct NotificationTranslationResult {
    let title: String
    let body: String
    let avatarFilePath: String?
    let attachmentFilePaths: String?
    let notificationType: PushNotificationType?
}

class NotificationTranslationService {
    private let translator: Translator<PushNotificationTranslations>
    private let storage: SharedStorageService
    private let encryptedMessageService: EncryptedMessageService?
    private let database: DatabaseManager?

    init(storage: SharedStorageService) {
        self.storage = storage

        let appLocale = storage.getAppLocale()
        let repository = TranslationsRepository<PushNotificationTranslations>(
            ionOrigin: Environment.ionOrigin,
            storage: storage,
            cacheMaxAge: TimeInterval(Environment.pushTranslationsCacheMinutes * 60)
        )

        self.translator = Translator<PushNotificationTranslations>(
            translationsRepository: repository,
            appLocale: appLocale
        )

        if let pubkey = storage.getCurrentPubkey(), let currentIdentityKeyName = storage.getCurrentIdentityKeyName() {
            self.encryptedMessageService = EncryptedMessageService(
                keychainService: KeychainService(currentIdentityKeyName: currentIdentityKeyName),
                pubkey: pubkey
            )
            self.database = DatabaseManager(storage: storage)
        } else {
            self.encryptedMessageService = nil
            self.database = nil
        }
    }

    func translate(_ pushPayload: [AnyHashable: Any]) async -> NotificationTranslationResult? {
        guard let currentPubkey = storage.getCurrentPubkey() else {
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
            notificationType: notificationType
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
                    metadata = self.getUserMetadataFromDatabase(pubkey: pubkey)
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

    /// Fetches user metadata from the SQLite database for a given pubkey
    /// - Parameter pubkey: The pubkey of the user to fetch metadata for
    /// - Returns: UserMetadata if found, nil otherwise
    private func getUserMetadataFromDatabase(pubkey: String) -> UserMetadata? {
        guard let database = database else {
            return nil
        }

        if !database.openDatabase() {
            NSLog("Failed to open database connection")
            return nil
        }

        defer { database.closeDatabase() }

        let query = "SELECT content FROM user_metadata_table WHERE master_pubkey = '\(pubkey)' ORDER BY created_at DESC LIMIT 1"

        guard let results = database.executeQuery(query) else {
            return nil
        }

        if results.isEmpty {
            NSLog("No user metadata found in database for pubkey: \(pubkey)")
            return nil
        }

        var content: String? = nil

        if let firstResult = results.first as? [String: Any], let contentValue = firstResult["content"] as? String {
            content = contentValue
        } else if let firstResult = results.first as? [Any], firstResult.count > 0 {
            if let contentDict = firstResult.first as? [String: String], let contentValue = contentDict["content"] {
                content = contentValue
            } else if let contentDict = firstResult.first as? [String: Any],
                let contentValue = contentDict["content"] as? String
            {
                content = contentValue
            }
        }

        guard let extractedContent = content else {
            return nil
        }

        guard let contentData = extractedContent.data(using: .utf8) else {
            NSLog("Failed to convert content string to data")
            return nil
        }

        do {
            let userData = try JSONDecoder().decode(
                UserDataEventMessageContent.self,
                from: contentData
            )

            // Create and return UserMetadata
            let metadata = UserMetadata(
                name: userData.name ?? "",
                displayName: userData.displayName ?? "",
                picture: userData.picture
            )

            return metadata
        } catch {
            NSLog("Error parsing user metadata: \(error)")
            return nil
        }
    }
}
