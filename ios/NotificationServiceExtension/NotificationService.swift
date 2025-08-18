// SPDX-License-Identifier: ice License 1.0

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var mutableNotificationContent: UNMutableNotificationContent?

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
                let translation = await NotificationTranslationService(storage: try SharedStorageService()).translate(request.content.userInfo)

                if let title = translation.title, let body = translation.body {
                    mutableNotificationContent.title = title
                    mutableNotificationContent.body = body
                }
            } catch {
                NSLog("Failed to translate notification: \(error)")
            }
            
            contentHandler(mutableNotificationContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let mutableNotificationContent = mutableNotificationContent {
            contentHandler(mutableNotificationContent)
        }
    }
}
