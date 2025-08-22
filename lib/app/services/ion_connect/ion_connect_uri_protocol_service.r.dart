// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_uri_protocol_service.r.g.dart';

///
/// https://github.com/nostr-protocol/nips/blob/master/21.md
///
class IonConnectUriProtocolService {
  static const String prefix = 'nostr:';

  String? decode(String uri) {
    if (!uri.startsWith(prefix)) {
      return null;
    }

    return uri.substring(prefix.length);
  }

  String encode(String content) => prefix + content;
}

@riverpod
IonConnectUriProtocolService ionConnectUriProtocolService(Ref ref) {
  return IonConnectUriProtocolService();
}
