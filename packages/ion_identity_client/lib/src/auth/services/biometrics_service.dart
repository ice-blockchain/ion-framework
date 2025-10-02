// SPDX-License-Identifier: ice License 1.0
import 'dart:io';

import 'package:local_auth/local_auth.dart';

class BiometricsService {
  const BiometricsService();

  /// Checks if biometrics are available and enabled on the device
  Future<bool> isBiometricsAvailable() async {
    final localAuth = LocalAuthentication();

    final results = await Future.wait<bool>([
      localAuth.canCheckBiometrics,
      localAuth.isDeviceSupported(),
      // We need to check additionally if the device has at least one type of biometrics set up.
      if (Platform.isAndroid) localAuth.getAvailableBiometrics().then((list) => list.isNotEmpty),
    ]);

    return results.every((element) => element);
  }
}
