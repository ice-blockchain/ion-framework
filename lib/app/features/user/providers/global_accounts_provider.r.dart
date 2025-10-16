// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/user/model/global_accounts.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_accounts_provider.r.g.dart';

@Riverpod(keepAlive: true)
class GlobalAccounts extends _$GlobalAccounts {
  @override
  Future<GlobalAccountsData> build() async {
    final repository = await ref.watch(configRepositoryProvider.future);
    final result = await repository.getConfig<GlobalAccountsData>(
      'global_accounts',
      cacheStrategy: AppConfigCacheStrategy.file,
      parser: (data) => GlobalAccountsData.fromJson(jsonDecode(data) as List<dynamic>),
      checkVersion: true,
    );
    await ref.read(userRelaysManagerProvider.notifier).cacheRelaysFromIdentity(result.list);
    return result;
  }
}
