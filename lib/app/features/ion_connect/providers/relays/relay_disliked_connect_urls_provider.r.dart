// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_disliked_connect_urls_provider.r.g.dart';

/// Holds a per-logical-relay set of connect URLs that should be avoided for the
/// current relay build / failover attempt.
///
/// This is intentionally separated from the Relay provider so other layers
/// (e.g. auth handling) can mark a connect URL as bad and force failover.
@Riverpod(keepAlive: true)
class RelayDislikedConnectUrls extends _$RelayDislikedConnectUrls {
  @override
  Set<String> build(String logicalRelayUrl) => <String>{};

  void reset() {
    state = <String>{};
  }

  /// Adds [connectUrl] to the disliked set.
  ///
  /// Returns `true` if the url was newly added.
  bool add(String connectUrl) {
    if (state.contains(connectUrl)) return false;
    state = {...state, connectUrl};
    return true;
  }
}
