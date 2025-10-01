// SPDX-License-Identifier: ice License 1.0

import Foundation

struct RelatedEvent {
    let eventReference: String  // Can be event ID (for "e" tags) or "kind:pubkey:dTag" (for "a" tags)
    let marker: RelatedEventMarker?
    let pubkey: String

    init(eventReference: String, marker: RelatedEventMarker?, pubkey: String) {
        self.eventReference = eventReference
        self.marker = marker
        self.pubkey = pubkey
    }

    static func fromTag(_ tag: [String]) -> RelatedEvent? {
        guard tag.count >= 5 else { return nil }
        
        // Support both "e" tags (immutable events) and "a" tags (replaceable events)
        guard tag[0] == "e" || tag[0] == "a" else { return nil }

        let eventReference = tag[1]
        // tag[2] is relay URL (optional, often empty string)
        let markerStr = tag[3]
        let pubkey = tag[4]

        let marker = RelatedEventMarker.fromValue(markerStr)

        return RelatedEvent(eventReference: eventReference, marker: marker, pubkey: pubkey)
    }
}
