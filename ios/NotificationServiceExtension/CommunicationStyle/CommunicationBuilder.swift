// SPDX-License-Identifier: ice License 1.0

import Foundation
import Intents
import UIKit
import UserNotifications

struct CommunicationPushData {
    let title: String
    let body: String
    let avatarFilePath: String?
    let attachmentFilePath: String?
}

final class CommunicationBuilder {
    func buildCommunicationContent(
        from content: UNMutableNotificationContent,
        communicationPushData: CommunicationPushData
    ) async -> UNMutableNotificationContent? {
        var resultContent = content

        let conversationIdentifier = communicationPushData.title
        let groupName = communicationPushData.title

        resultContent.threadIdentifier = conversationIdentifier

        let messageText = communicationPushData.body

        let latestHandle = communicationPushData.title
        let latestDisplayName = communicationPushData.title
        let latestAvatarPath = communicationPushData.avatarFilePath

        let personHandle = INPersonHandle(value: latestHandle, type: .unknown)

        let avatar: INImage? = {
            if let path = latestAvatarPath, FileManager.default.fileExists(atPath: path),
                let data = try? Data(contentsOf: URL(fileURLWithPath: path)), !data.isEmpty
            {
                return INImage(imageData: data)
            }

            return INImage(named: "")
        }()

        let sender = INPerson(
            personHandle: personHandle,
            nameComponents: nil,
            displayName: latestDisplayName,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: latestHandle
        )

        let speakableGroupName: INSpeakableString? = {
            return INSpeakableString(vocabularyIdentifier: groupName, spokenPhrase: groupName, pronunciationHint: nil)
        }()

        let intent = INSendMessageIntent(
            recipients: [],
            outgoingMessageType: .outgoingMessageText,
            content: messageText,
            speakableGroupName: speakableGroupName,
            conversationIdentifier: conversationIdentifier,
            serviceName: nil,
            sender: sender,
            attachments: nil
        )

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming

        do {
            try await interaction.donate()
        } catch {
            NSLog("[NSE] [CommunicationBuilder] donate failed: \(error)")
        }

        if let path = communicationPushData.attachmentFilePath, !path.isEmpty, FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            if let attachment = try? UNNotificationAttachment(identifier: path, url: url, options: nil) {
                resultContent.attachments = [attachment]
            }
        }

        do {
            let enriched = try resultContent.updating(from: intent)
            if let enrichedContent = enriched as? UNMutableNotificationContent {
                resultContent = enrichedContent
            } else {
                let mutable = enriched.mutableCopy() as? UNMutableNotificationContent
                resultContent = mutable ?? resultContent
            }
        } catch {
            NSLog("[NSE] [CommunicationBuilder] updating(from:) failed: \(error)")
        }

        return resultContent
    }
}
