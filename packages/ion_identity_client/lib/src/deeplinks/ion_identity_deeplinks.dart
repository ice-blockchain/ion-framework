// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/deeplinks/services/send_deeplink/send_deeplink_service.dart';

class IONIdentityDeeplinks {
  const IONIdentityDeeplinks(
    this.username,
    this._sendDeeplinkService,
  );

  final String username;
  final SendDeeplinkService _sendDeeplinkService;

  /// Sends a deeplink to the backend for a given event address
  Future<void> sendDeeplink({
    required String eventAddress,
    required String deeplink,
  }) =>
      _sendDeeplinkService.sendDeeplink(
        eventAddress: eventAddress,
        deeplink: deeplink,
      );
}
