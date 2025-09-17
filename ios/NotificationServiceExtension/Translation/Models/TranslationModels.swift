// SPDX-License-Identifier: ice License 1.0

import Foundation

protocol TranslationWithVersion: Decodable {
    var version: Int { get }
}

struct NotificationTranslation: Decodable {
    let title: String?
    let body: String?
}

struct PushNotificationTranslations: TranslationWithVersion, Decodable {
    let version: Int
    let reply: NotificationTranslation?
    let mention: NotificationTranslation?
    let repost: NotificationTranslation?
    let quote: NotificationTranslation?
    let like: NotificationTranslation?
    let follower: NotificationTranslation?
    let paymentRequest: NotificationTranslation?
    let paymentReceived: NotificationTranslation?
    let chatDocumentMessage: NotificationTranslation?
    let chatEmojiMessage: NotificationTranslation?
    let chatPhotoMessage: NotificationTranslation?
    let chatProfileMessage: NotificationTranslation?
    let chatReaction: NotificationTranslation?
    let chatSharePostMessage: NotificationTranslation?
    let chatShareStoryMessage: NotificationTranslation?
    let chatSharedStoryReplyMessage: NotificationTranslation?
    let chatTextMessage: NotificationTranslation?
    let chatVideoMessage: NotificationTranslation?
    let chatVoiceMessage: NotificationTranslation?
    let chatFirstContactMessage: NotificationTranslation?
    let chatGifMessage: NotificationTranslation?
    let chatMultiGifMessage: NotificationTranslation?
    let chatMultiMediaMessage: NotificationTranslation?
    let chatMultiPhotoMessage: NotificationTranslation?
    let chatMultiVideoMessage: NotificationTranslation?
    let chatPaymentRequestMessage: NotificationTranslation?
    let chatPaymentReceivedMessage: NotificationTranslation?
    
    enum CodingKeys: String, CodingKey {
        case version = "_version"
        case reply, mention, repost, quote, like, follower
        case paymentRequest, paymentReceived
        case chatDocumentMessage, chatEmojiMessage, chatPhotoMessage
        case chatProfileMessage, chatReaction, chatSharePostMessage
        case chatShareStoryMessage, chatSharedStoryReplyMessage, chatTextMessage
        case chatVideoMessage, chatVoiceMessage, chatFirstContactMessage
        case chatGifMessage, chatMultiGifMessage, chatMultiMediaMessage
        case chatMultiPhotoMessage, chatMultiVideoMessage
        case chatPaymentRequestMessage, chatPaymentReceivedMessage
    }
}
