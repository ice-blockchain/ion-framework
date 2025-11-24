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
                let storage = try SharedStorage()
                let keysStorage = KeysStorage(storage: storage)
                let appBadgeCounter = AppBadgeCounterService(storage: storage)
                
                guard let result = await NotificationTranslationService(
                    appLocaleStorage: AppLocaleStorage(storage: storage),
                    keysStorage: keysStorage
                ).translate(
                    request.content.userInfo
                ) else {
                    // Hide notification if translation fails
                    NSLog("[NSE] Translation failed, hiding notification")
                    contentHandler(UNNotificationContent())
                    return
                }

                // Handle badge count based on notification type
                if let notificationType = result.notificationType, !notificationType.isChat {
                    incrementBadge(appBadgeCounter: appBadgeCounter, 
                                 mutableContent: mutableNotificationContent, 
                                 category: .inapp)
                } else if let conversationId = result.groupKey {
                    // Chat notification - check if we should increment
                    handleChatNotificationBadge(
                        conversationId: conversationId,
                        keysStorage: keysStorage,
                        appBadgeCounter: appBadgeCounter,
                        mutableContent: mutableNotificationContent
                    )
                }

                mutableNotificationContent.title = result.title
                mutableNotificationContent.body = result.body

                communicationPushData = CommunicationPushData(
                    title: result.title,
                    body: result.body,
                    avatarFilePath: result.avatarFilePath,
                    attachmentFilePath: result.attachmentFilePaths,
                    groupKey: result.groupKey
                )
            } catch {
                // Hide notification if any error occurs during processing
                NSLog("[NSE] Failed to process notification: \(error)")
                contentHandler(UNNotificationContent())
                return
            }

            if let communicationPushData = communicationPushData {
                let communicationStyle = await CommunicationBuilder().buildCommunicationContent(
                    from: mutableNotificationContent,
                    communicationPushData: communicationPushData
                )

                if let communicationStyle = communicationStyle {
                    contentHandler(communicationStyle)
                } else {
                    // Hide notification if communication style building fails
                    NSLog("[NSE] Failed to build communication style, hiding notification")
                    contentHandler(UNNotificationContent())
                }
            } else {
                // Hide notification if no communication data
                NSLog("[NSE] No communication data, hiding notification")
                contentHandler(UNNotificationContent())
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler {
            // Hide notification if processing times out
            NSLog("[NSE] Service extension time expired, hiding notification")
            contentHandler(UNNotificationContent())
        }
    }
    
    // MARK: - Badge Methods
    
    private func incrementBadge(
        appBadgeCounter: AppBadgeCounterService,
        mutableContent: UNMutableNotificationContent,
        category: CounterCategory
    ) {
        let currentCount = appBadgeCounter.getBadgeCount(for: category)
        let newCount = currentCount + 1
        
        appBadgeCounter.setBadgeCount(newCount, category: category)
        mutableContent.badge = NSNumber(value: appBadgeCounter.getTotalBadgeCount())
    }
    
    private func handleChatNotificationBadge(
        conversationId: String,
        keysStorage: KeysStorage,
        appBadgeCounter: AppBadgeCounterService,
        mutableContent: UNMutableNotificationContent
    ) {
        let chatDB = ChatDatabase(keysStorage: keysStorage)
        guard chatDB.openDatabase() else {
            NSLog("[NSE] Failed to open chat database")
            return
        }
        defer { chatDB.closeDatabase() }
        
        let conversationExists = chatDB.checkIfConversationExists(conversationId: conversationId)
        
        let alreadyCounted = appBadgeCounter.isUnreadConversation(conversationId)
        
        if conversationExists && !alreadyCounted {
            incrementBadge(appBadgeCounter: appBadgeCounter, 
                         mutableContent: mutableContent, 
                         category: .chat)
            appBadgeCounter.setUnreadConversation(conversationId)
        } else if !conversationExists {
            incrementBadge(appBadgeCounter: appBadgeCounter, 
                         mutableContent: mutableContent, 
                         category: .chat)
            appBadgeCounter.setUnreadConversation(conversationId)
        }
    }
}
