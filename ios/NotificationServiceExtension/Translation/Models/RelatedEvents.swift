// SPDX-License-Identifier: ice License 1.0

import Foundation

struct RelatedEvent {
    let eventReference: EventReference
    let marker: RelatedEventMarker?
    let pubkey: String

    init(eventReference: EventReference, marker: RelatedEventMarker?, pubkey: String) {
        self.eventReference = eventReference
        self.marker = marker
        self.pubkey = pubkey
    }

    static func fromTag(_ tag: [String]) -> RelatedEvent? {
        guard tag.count >= 5 else { return nil }
        
        // tag[2] is relay URL (optional, often empty string)
        let markerStr = tag[3]
        let pubkey = tag[4]

        let marker = RelatedEventMarker.fromValue(markerStr)

        // Support both "e" tags (immutable events) and "a" tags (replaceable events)
        let eventRef: EventReference
        if tag[0] == "e" {
            // Immutable event reference
            eventRef = ImmutableEventReference(id: tag[1], pubkey: pubkey)
        } else if tag[0] == "a" {
            // Replaceable event reference (format: "kind:pubkey:dTag")
            eventRef = ReplaceableEventReference.fromString(tag[1])
        } else {
            return nil
        }

        return RelatedEvent(eventReference: eventRef, marker: marker, pubkey: pubkey)
    }
}
