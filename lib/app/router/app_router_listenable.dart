// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/init_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/feed/providers/android_soft_update.m.dart';
import 'package:ion/app/features/force_update/providers/force_update_provider.r.dart';

class AppRouterNotifier extends ChangeNotifier {
  AppRouterNotifier(this.ref) {
    ref
      ..listen(forceUpdateProvider, (_, __) => notifyListeners())
      ..listen(authProvider, (_, __) => notifyListeners())
      ..listen(initAppProvider, (_, __) => notifyListeners())
      ..listen(splashProvider, (_, __) => notifyListeners())
      ..listen(onboardingCompleteProvider, (_, __) => notifyListeners())
      ..listen(userSwitchInProgressProvider, (_, __) => notifyListeners())
      ..listen(
        androidSoftUpdateProvider.select((state) => state.isUpdateAvailable),
        (_, __) => notifyListeners(),
      );
  }

  final Ref ref;
}
