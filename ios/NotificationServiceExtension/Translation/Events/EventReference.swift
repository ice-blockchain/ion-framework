// SPDX-License-Identifier: ice License 1.0

import Foundation

protocol EventReference {
    var masterPubkey: String { get }
    func toString() -> String
}

/// A simple event reference implementation that just stores an ID
struct SimpleEventReference: EventReference {
    let id: String
    let masterPubkey: String = ""

    init(id: String) {
        self.id = id
    }

    func toString() -> String {
        return id
    }
}

/// Utility class for creating EventReference instances
class EventReferenceFactory {
    /// Creates an EventReference from an encoded string
    static func fromEncoded(_ encoded: String) -> EventReference? {
        // First check if it's an ImmutableEventReference (nevent)
        if let immutableRef = ImmutableEventReference.fromEncoded(encoded) {
            return immutableRef
        }

        // Then check if it's a ReplaceableEventReference (naddr or nprofile)
        if let replaceableRef = ReplaceableEventReference.fromEncoded(encoded) {
            return replaceableRef
        }

        // If we can't decode it, return nil
        return nil
    }
}

struct ReplaceableEventReference: EventReference {
    let masterPubkey: String
    let kind: Int

    init(masterPubkey: String, kind: Int) {
        self.masterPubkey = masterPubkey
        self.kind = kind
    }

    static func fromEncoded(_ encoded: String) -> EventReference? {
        // Check if the encoded string is in the naddr format
        if encoded.hasPrefix("nostr:naddr") || encoded.hasPrefix("naddr") {
            // In a real implementation, you would use a Bech32 decoder here
            // For now, we'll just return a placeholder
            return ReplaceableEventReference(masterPubkey: "", kind: 0)
        }

        // Check if the encoded string is in the nprofile format
        if encoded.hasPrefix("nostr:nprofile") || encoded.hasPrefix("nprofile") {
            // In a real implementation, you would use a Bech32 decoder here
            // For now, we'll just return a placeholder
            return ReplaceableEventReference(masterPubkey: "", kind: 0)
        }

        return nil
    }

    static func fromString(_ string: String) -> ReplaceableEventReference {
        let components = string.split(separator: ":")
        guard components.count >= 2,
            let kind = Int(components[0])
        else {
            // Default fallback if parsing fails
            return ReplaceableEventReference(masterPubkey: "", kind: 0)
        }

        return ReplaceableEventReference(
            masterPubkey: String(components[1]),
            kind: kind
        )
    }

    static func fromShareableIdentifier(_ identifier: ShareableIdentifier) -> ReplaceableEventReference {
        // In a real implementation, you would extract pubkey and kind from the identifier
        // For now, we'll just return a placeholder
        return ReplaceableEventReference(masterPubkey: "", kind: 0)
    }

    func toString() -> String {
        return "\(masterPubkey):\(kind)"
    }

    func encode() -> String {
        if kind == UserMetadataEntity.kind {
            do {
                return try IonConnectUriIdentifierService().encode(
                    prefix: IonConnectProtocolIdentifierType.nprofile,
                    special: masterPubkey
                )
            } catch {
                NSLog("Falied to encode: \(error)")
                return toString()
            }

        }

        return toString()
    }
}

struct ImmutableEventReference: EventReference {
    let id: String
    let pubkey: String
    let kind: Int
    let masterPubkey: String

    init(id: String, pubkey: String, kind: Int = 0, masterPubkey: String = "") {
        self.id = id
        self.pubkey = pubkey
        self.kind = kind
        self.masterPubkey = masterPubkey
    }

    static func fromEncoded(_ encoded: String) -> EventReference? {
        // Check if the encoded string is in the nevent format
        if encoded.hasPrefix("nostr:nevent") || encoded.hasPrefix("nevent") {
            // In a real implementation, you would use a Bech32 decoder here
            // For now, we'll just return a placeholder with a default kind
            return ImmutableEventReference(id: "", pubkey: "", kind: 0)
        }

        return nil
    }

    static func fromShareableIdentifier(_ identifier: ShareableIdentifier) -> ImmutableEventReference {
        // In a real implementation, you would extract id, pubkey, and kind from the identifier
        // For now, we'll just return a placeholder
        return ImmutableEventReference(id: "", pubkey: "")
    }

    static func fromString(_ string: String) -> ImmutableEventReference {
        // For immutable events, the string is just the event ID
        // The pubkey should be provided separately
        return ImmutableEventReference(id: string, pubkey: "")
    }

    func toString() -> String {
        return id
    }
}
