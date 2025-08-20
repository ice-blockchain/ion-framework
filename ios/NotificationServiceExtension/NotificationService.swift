// SPDX-License-Identifier: ice License 1.0

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var mutableNotificationContent: UNMutableNotificationContent?
    var communicationPushData: CommunicationPushData?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        mutableNotificationContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let mutableNotificationContent = mutableNotificationContent else {
            contentHandler(request.content)
            return
        }

        Task {
            do {
                let result = await NotificationTranslationService(storage: try SharedStorageService()).translate(
                    request.content.userInfo
                )

                if let result = result {
                    mutableNotificationContent.title = result.title
                    mutableNotificationContent.body = result.body

                    if result.notificationType.isChat {
                        communicationPushData = CommunicationPushData(
                            title: result.title,
                            body: result.body,
                            avatarFilePath: result.avatarFilePath,
                            attachmentFilePath: result.attachmentFilePaths
                        )
                    }

                }
            } catch {
                NSLog("Failed to translate notification: \(error)")
            }

            if let communicationPushData = communicationPushData {
                let communicationStyle = await CommunicationBuilder().buildCommunicationContent(
                    from: mutableNotificationContent,
                    communicationPushData: communicationPushData
                )

                if let communicationStyle = communicationStyle {
                    contentHandler(communicationStyle)
                } else {
                    contentHandler(mutableNotificationContent)
                }

            } else {
                contentHandler(mutableNotificationContent)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let mutableNotificationContent = mutableNotificationContent {
            contentHandler(mutableNotificationContent)
        }
    }
}
