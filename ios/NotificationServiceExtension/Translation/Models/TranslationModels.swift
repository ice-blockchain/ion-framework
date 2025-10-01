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
    let replyArticle: NotificationTranslation?
    let replyComment: NotificationTranslation?
    let mention: NotificationTranslation?
    let repost: NotificationTranslation?
    let repostArticle: NotificationTranslation?
    let repostComment: NotificationTranslation?
    let quote: NotificationTranslation?
    let quoteArticle: NotificationTranslation?
    let quoteComment: NotificationTranslation?
    let like: NotificationTranslation?
    let likeArticle: NotificationTranslation?
    let likeComment: NotificationTranslation?
    let likeStory: NotificationTranslation?
    let follower: NotificationTranslation?
    let paymentRequest: NotificationTranslation?
    let paymentReceived: NotificationTranslation?
    let chatDocumentMessage: NotificationTranslation?
    let chatEmojiMessage: NotificationTranslation?
    let chatPhotoMessage: NotificationTranslation?
    let chatProfileMessage: NotificationTranslation?
    let chatReaction: NotificationTranslation?
    let chatSharePostMessage: NotificationTranslation?
    let chatShareArticleMessage: NotificationTranslation?
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
        case reply, replyArticle, replyComment
        case mention
        case repost, repostArticle, repostComment
        case quote, quoteArticle, quoteComment
        case like, likeArticle, likeComment, likeStory
        case follower
        case paymentRequest, paymentReceived
        case chatDocumentMessage, chatEmojiMessage, chatPhotoMessage
        case chatTextMessage, chatProfileMessage, chatReaction
        case chatSharePostMessage, chatShareArticleMessage, chatShareStoryMessage, chatSharedStoryReplyMessage
        case chatVideoMessage, chatVoiceMessage, chatFirstContactMessage
        case chatGifMessage, chatMultiGifMessage, chatMultiMediaMessage
        case chatMultiPhotoMessage, chatMultiVideoMessage
        case chatPaymentRequestMessage, chatPaymentReceivedMessage
    }
}
