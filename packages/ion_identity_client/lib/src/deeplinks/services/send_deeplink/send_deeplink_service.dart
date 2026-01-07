// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/deeplinks/services/send_deeplink/data_sources/send_deeplink_data_source.dart';

class SendDeeplinkService {
  const SendDeeplinkService(
    this.username,
    this._sendDeeplinkDataSource,
  );

  final String username;
  final SendDeeplinkDataSource _sendDeeplinkDataSource;

  /// Sends a deeplink to the backend for a given event address
  Future<void> sendDeeplink({
    required String eventAddress,
    required String deeplink,
  }) async {
    await _sendDeeplinkDataSource.sendDeeplink(
      username,
      eventAddress: eventAddress,
      deeplink: deeplink,
    );
  }
}
