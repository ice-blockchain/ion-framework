// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nsfw_accounts_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<Set<String>> nsfwAccounts(Ref ref) async {
  final repo = await ref.watch(configRepositoryProvider.future);
  final result = await repo.getConfig<Set<String>>(
    'nsfw_accounts',
    cacheStrategy: AppConfigCacheStrategy.file,
    // Using Set (LinkedHashSet) for fast lookup
    parser: (data) => (jsonDecode(data) as List<dynamic>).cast<String>().toSet(),
    checkVersion: true,
    refreshInterval: const Duration(seconds: 1),
  );
  return result;
}
