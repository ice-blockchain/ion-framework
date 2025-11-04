// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_privacy_cache_expiration_duration_provider.r.g.dart';

@riverpod
Duration chatPrivacyCacheExpirationDuration(Ref ref) {
  return Duration(
    minutes: ref.watch(envProvider.notifier).get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES),
  );
}
