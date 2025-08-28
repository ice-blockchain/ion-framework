// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skip_countries_provider.r.g.dart';

const _skipCountriesKey = 'blacklisted_countries_phone2fa';

/// Remote config that returns a list of ISO country codes to skip/hide.
/// Expected payload example: ["IR", "KP"]
@riverpod
Future<Set<String>> skipCountriesIsoSet(Ref ref) async {
  try {
    final repo = await ref.watch(configRepositoryProvider.future);
    final result = await repo.getConfig<List<String>>(
      _skipCountriesKey,
      cacheStrategy: AppConfigCacheStrategy.localStorage,
      parser: (data) => (jsonDecode(data) as List<dynamic>).cast<String>(),
      checkVersion: true,
    );

    return result.map((e) => e.toUpperCase()).toSet();
  } catch (error, stackTrace) {
    Logger.error(
      error,
      stackTrace: stackTrace,
      message: 'Failed to load phone skip countries config',
    );
    return <String>{};
  }
}
