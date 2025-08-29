// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/user/model/global_accounts.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_accounts_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<GlobalAccounts> globalAccounts(Ref ref) async {
  final repository = await ref.watch(configRepositoryProvider.future);
  final result = await repository.getConfig<GlobalAccounts>(
    'global_accounts',
    cacheStrategy: AppConfigCacheStrategy.file,
    parser: (data) => GlobalAccounts.fromJson(jsonDecode(data) as List<dynamic>),
    checkVersion: true,
  );
  return result;
}
