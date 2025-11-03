// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/logger/logger.dart';

void useInvalidateOnDispose<T>(WidgetRef ref, ProviderBase<T> provider) {
  useEffect(
    () {
      return () {
        Logger.info('🔥 invalidating provider: $provider');
        ref.invalidate(provider);
      };
    },
    [],
  );
}
