// SPDX-License-Identifier: ice License 0.1

import Foundation

struct ModifiablePostEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: ModifiablePostData

    static let kind = 30175

    init(id: String, pubkey: String, masterPubkey: String, signature: String, createdAt: Int, data: ModifiablePostData) {
        self.id = id
        self.pubkey = pubkey
        self.masterPubkey = masterPubkey
        self.signature = signature
        self.createdAt = createdAt
        self.data = data
    }

    static func fromEventMessage(_ eventMessage: EventMessage) throws -> ModifiablePostEntity {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage.id, kind: kind)
        }

        let masterPubkey = try eventMessage.masterPubkey()

        return ModifiablePostEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: masterPubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: ModifiablePostData.fromEventMessage(eventMessage)
        )
    }
}

struct ModifiablePostData {
    let textContent: String
    let relatedEvents: [RelatedEvent]
    let relatedPubkeys: [RelatedPubkey]
    let quotedEvent: QuotedEvent?

    static func fromEventMessage(_ eventMessage: EventMessage) -> ModifiablePostData {
        let textContent = eventMessage.content

        // Parse related events from e tags
        var relatedEvents: [RelatedEvent] = []
        for tag in eventMessage.tags {
            if tag.count >= 4 && tag[0] == "e" {
                if let relatedEvent = RelatedEvent.fromTag(tag) {
                    relatedEvents.append(relatedEvent)
                }
            }
        }

        // Parse related pubkeys from p tags
        var relatedPubkeys: [RelatedPubkey] = []
        for tag in eventMessage.tags {
            if tag.count >= 2 && tag[0] == "p" {
                if let relatedPubkey = RelatedPubkey.fromTag(tag) {
                    relatedPubkeys.append(relatedPubkey)
                }
            }
        }

        // Parse quoted event from q or Q tags
        var quotedEvent: QuotedEvent? = nil
        for tag in eventMessage.tags {
            if tag.count >= 4 && (tag[0] == "q" || tag[0] == "Q") {
                do {
                    quotedEvent = try QuotedEventFactory.fromTag(tag)
                    break
                } catch {
                    NSLog("Error parsing quoted event: \(error)")
                }
            }
        }

        return ModifiablePostData(
            textContent: textContent,
            relatedEvents: relatedEvents,
            relatedPubkeys: relatedPubkeys,
            quotedEvent: quotedEvent
        )
    }
}
