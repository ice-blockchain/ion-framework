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
                
                let result = await NotificationTranslationService(
                    appLocaleStorage: AppLocaleStorage(storage: storage),
                    keysStorage: keysStorage
                ).translate(
                    request.content.userInfo
                )

                // Handle badge count based on notification type
                if let notificationType = result?.notificationType, !notificationType.isChat {
                    incrementBadge(appBadgeCounter: appBadgeCounter, 
                                 mutableContent: mutableNotificationContent, 
                                 category: .inapp)
                } else if let conversationId = result?.conversationId {
                    // Chat notification - check if we should increment
                    handleChatNotificationBadge(
                        conversationId: conversationId,
                        keysStorage: keysStorage,
                        appBadgeCounter: appBadgeCounter,
                        mutableContent: mutableNotificationContent
                    )
                }

                if let result = result {
                    mutableNotificationContent.title = result.title
                    mutableNotificationContent.body = result.body

                    communicationPushData = CommunicationPushData(
                        title: result.title,
                        body: result.body,
                        avatarFilePath: result.avatarFilePath,
                        attachmentFilePath: result.attachmentFilePaths,
                        conversationId: result.conversationId
                    )

                }
            } catch {
                NSLog("[NSE] Failed to translate notification: \(error)")
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
            do {
                let storage = try SharedStorage()
                let badgeCounter = AppBadgeCounterService(storage: storage)
                incrementBadge(appBadgeCounter: badgeCounter, 
                             mutableContent: mutableNotificationContent, 
                             category: .inapp)
            } catch {}

            contentHandler(mutableNotificationContent)
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
