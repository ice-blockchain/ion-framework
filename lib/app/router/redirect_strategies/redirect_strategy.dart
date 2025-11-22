// SPDX-License-Identifier: ice License 1.0

// lib/app/router/redirect_strategies/redirect_strategy.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class RedirectStrategy {
  Future<String?> getRedirect({
    required String location,
    required Ref ref,
  });
}
