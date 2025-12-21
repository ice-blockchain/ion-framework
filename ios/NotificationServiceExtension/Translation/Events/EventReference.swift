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
        let proto = IonConnectUriProtocolService()
        guard let payload = proto.decode(encoded) else {
            return nil
        }

        do {
            let identifier = try IonConnectUriIdentifierService().decodeShareableIdentifiers(payload: payload)
            switch identifier.prefix {
            case .nevent:
                let ref = ImmutableEventReference.fromShareableIdentifier(identifier)
                return ref
            case .naddr, .nprofile:
                let ref = ReplaceableEventReference.fromShareableIdentifier(identifier)
                return ref
            }
        } catch {
            return nil
        }
    }
}

struct ReplaceableEventReference: EventReference {
    let masterPubkey: String
    let kind: Int
    let dTag: String

    init(masterPubkey: String, kind: Int, dTag: String = "") {
        self.masterPubkey = masterPubkey
        self.kind = kind
        self.dTag = dTag
    }

    static func fromEncoded(_ encoded: String) -> EventReference? {
        // Check if the encoded string is in the naddr format
        if encoded.hasPrefix("nostr:naddr") || encoded.hasPrefix("ion:naddr") || encoded.hasPrefix("naddr") {
            // In a real implementation, you would use a Bech32 decoder here
            // For now, we'll just return a placeholder
            return ReplaceableEventReference(masterPubkey: "", kind: 0)
        }

        // Check if the encoded string is in the nprofile format
        if encoded.hasPrefix("nostr:nprofile") || encoded.hasPrefix("ion:nprofile") || encoded.hasPrefix("nprofile") {
            // In a real implementation, you would use a Bech32 decoder here
            // For now, we'll just return a placeholder
            return ReplaceableEventReference(masterPubkey: "", kind: 0)
        }

        return nil
    }

    static func fromString(_ string: String) -> ReplaceableEventReference {
        let components = string.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard components.count >= 2, let kind = Int(components[0]) else {
            return ReplaceableEventReference(masterPubkey: "", kind: 0, dTag: "")
        }
        let master = components[1]
        let d = components.count >= 3 ? components[2] : ""
        return ReplaceableEventReference(masterPubkey: master, kind: kind, dTag: d)
    }

    static func fromShareableIdentifier(_ identifier: ShareableIdentifier) -> ReplaceableEventReference {
        switch identifier.prefix {
        case .nprofile:
            // nprofile -> replaceable ref for user metadata (kind of user metadata)
            return ReplaceableEventReference(
                masterPubkey: identifier.special,
                kind: UserMetadataEntity.kind,
                dTag: ""
            )
        case .naddr:
            guard let author = identifier.author, let kind = identifier.kind else {
                NSLog("[NSE] ReplaceableEventReference.fromShareableIdentifier: missing author/kind for naddr")
                return ReplaceableEventReference(masterPubkey: "", kind: 0, dTag: "")
            }
            return ReplaceableEventReference(
                masterPubkey: author,
                kind: kind,
                dTag: identifier.special
            )
        default:
            NSLog("[NSE] ReplaceableEventReference.fromShareableIdentifier: unsupported prefix \(identifier.prefix)")
            return ReplaceableEventReference(masterPubkey: "", kind: 0, dTag: "")
        }
    }

    func toString() -> String {
        return "\(kind):\(masterPubkey):\(dTag)"
    }

    func encode() -> String {
        if kind == UserMetadataEntity.kind {
            do {
                return try IonConnectUriIdentifierService().encode(
                    prefix: IonConnectProtocolIdentifierType.nprofile,
                    special: masterPubkey
                )
            } catch {
                NSLog("[NSE] Falied to encode: \(error)")
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
        if encoded.hasPrefix("nostr:nevent") || encoded.hasPrefix("ion:nevent") || encoded.hasPrefix("nevent") {
            // In a real implementation, you would use a Bech32 decoder here
            // For now, we'll just return a placeholder with a default kind
            return ImmutableEventReference(id: "", pubkey: "", kind: 0)
        }

        return nil
    }

    static func fromShareableIdentifier(_ identifier: ShareableIdentifier) -> ImmutableEventReference {
        // Expect nevent: special = eventId (hex), author = pubkey (hex), kind = optional
        guard case .nevent = identifier.prefix else {
            NSLog("[NSE] ImmutableEventReference.fromShareableIdentifier: unsupported prefix \(identifier.prefix)")
            return ImmutableEventReference(id: "", pubkey: "")
        }
        guard let author = identifier.author else {
            NSLog("[NSE] ImmutableEventReference.fromShareableIdentifier: missing author for nevent")
            return ImmutableEventReference(id: identifier.special, pubkey: "", kind: identifier.kind ?? 0, masterPubkey: "")
        }
        return ImmutableEventReference(
            id: identifier.special,
            pubkey: author,
            kind: identifier.kind ?? 0,
            masterPubkey: author
        )
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
