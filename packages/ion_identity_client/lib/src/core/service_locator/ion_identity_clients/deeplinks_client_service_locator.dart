// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_service_locator.dart';
import 'package:ion_identity_client/src/deeplinks/ion_identity_deeplinks.dart';
import 'package:ion_identity_client/src/deeplinks/services/send_deeplink/data_sources/send_deeplink_data_source.dart';
import 'package:ion_identity_client/src/deeplinks/services/send_deeplink/send_deeplink_service.dart';

class DeeplinksClientServiceLocator {
  factory DeeplinksClientServiceLocator() {
    return _instance;
  }

  DeeplinksClientServiceLocator._internal();

  static final DeeplinksClientServiceLocator _instance = DeeplinksClientServiceLocator._internal();

  IONIdentityDeeplinks deeplinks({
    required String username,
    required IONIdentityConfig config,
  }) {
    return IONIdentityDeeplinks(
      username,
      sendDeeplink(username: username, config: config),
    );
  }

  SendDeeplinkService sendDeeplink({
    required String username,
    required IONIdentityConfig config,
  }) {
    return SendDeeplinkService(
      username,
      SendDeeplinkDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }
}
