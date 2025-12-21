// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_uri_protocol_service.r.g.dart';

///
/// https://github.com/nostr-protocol/nips/blob/master/21.md
///
class IonConnectUriProtocolService {
  static const String nostrPrefix = 'nostr:';
  static const String ionPrefix = 'ion:';

  /// Decodes a URI by removing the protocol prefix.
  /// Returns null if the URI doesn't start with a supported prefix.
  String? decode(String uri) {
    if (!uri.startsWith(nostrPrefix) && !uri.startsWith(ionPrefix)) {
      return null;
    }

    // For backwards compatibility
    if (uri.startsWith(nostrPrefix)) {
      return uri.substring(nostrPrefix.length);
    }

    return uri.substring(ionPrefix.length);
  }

  String encode(String content) => ionPrefix + content;
}

@riverpod
IonConnectUriProtocolService ionConnectUriProtocolService(Ref ref) {
  return IonConnectUriProtocolService();
}
