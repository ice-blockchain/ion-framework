// SPDX-License-Identifier: ice License 1.0

final class IonConnectUriProtocolService {
    static let prefix = "nostr:"

    func decode(_ uri: String) -> String? {
        guard uri.hasPrefix(Self.prefix) else { return nil }
        return String(uri.dropFirst(Self.prefix.count))
    }

    func encode(_ content: String) -> String {
        return Self.prefix + content
    }
}
