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
    static let storyKind = 57103

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
    
    func toReplaceableEventReference() -> ReplaceableEventReference {
        return ReplaceableEventReference(
            masterPubkey: masterPubkey,
            kind: ModifiablePostEntity.kind,
            dTag: data.replaceableEventId.value
        )
    }
}

struct ModifiablePostData {
    let textContent: String
    let replaceableEventId: ReplaceableEventIdentifier
    let relatedEvents: [RelatedEvent]
    let relatedPubkeys: [RelatedPubkey]
    let quotedEvent: QuotedEvent?
    let richText: RichText?
    let expiration: EntityExpiration?
    
    var content: String {
        return richText?.content ?? textContent
    }
    
    var parentEvent: RelatedEvent? {
        var rootParent: RelatedEvent? = nil
        var replyParent: RelatedEvent? = nil
        
        for relatedEvent in relatedEvents {
            if relatedEvent.marker == .reply {
                replyParent = relatedEvent
                break
            } else if relatedEvent.marker == .root {
                rootParent = relatedEvent
            }
        }
        
        return replyParent ?? rootParent
    }

    static func fromEventMessage(_ eventMessage: EventMessage) -> ModifiablePostData {
        let textContent = eventMessage.content
        
        // Parse replaceable event identifier from d tag
        var replaceableEventId: ReplaceableEventIdentifier?
        for tag in eventMessage.tags {
            if tag.count >= 2 && tag[0] == ReplaceableEventIdentifier.tagName {
                replaceableEventId = ReplaceableEventIdentifier.fromTag(tag)
                break
            }
        }
        
        // Use a default value if d tag is not found (should not happen in valid events)
        let eventId = replaceableEventId ?? ReplaceableEventIdentifier(value: "")

        // Parse related events from e tags (immutable) and a tags (replaceable)
        var relatedEvents: [RelatedEvent] = []
        for tag in eventMessage.tags {
            if tag.count >= 5 && (tag[0] == "e" || tag[0] == "a") {
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
                    NSLog("[NSE] Error parsing quoted event: \(error)")
                }
            }
        }
        
        // Parse rich text from rich_text tags
        var richText: RichText? = nil
        for tag in eventMessage.tags {
            if tag.count >= 3 && tag[0] == RichText.tagName {
                do {
                    richText = try RichText.fromTag(tag)
                    break
                } catch {
                    NSLog("[NSE] Error parsing rich text: \(error)")
                }
            }
        }
        
        // Parse expiration from expiration tags
        var expiration: EntityExpiration? = nil
        for tag in eventMessage.tags {
            if tag.count >= 2 && tag[0] == EntityExpiration.tagName {
                expiration = EntityExpiration.fromTag(tag)
                break
            }
        }

        return ModifiablePostData(
            textContent: textContent,
            replaceableEventId: eventId,
            relatedEvents: relatedEvents,
            relatedPubkeys: relatedPubkeys,
            quotedEvent: quotedEvent,
            richText: richText,
            expiration: expiration
        )
    }
}
