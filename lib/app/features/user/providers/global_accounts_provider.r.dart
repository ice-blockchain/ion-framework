// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_db_cache_notifier.r.dart';
import 'package:ion/app/features/user/model/global_accounts.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_accounts_provider.r.g.dart';

@riverpod
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
    await _cacheRelays(result);
    return result;
  }

  Future<void> _cacheRelays(GlobalAccountsData globalAccounts) async {
    final relayEntities = globalAccounts.list
        .map(
          (account) => UserRelaysEntity(
            id: '',
            pubkey: account.masterPubKey,
            masterPubkey: account.masterPubKey,
            signature: '',
            createdAt: DateTime.now().microsecondsSinceEpoch,
            data: UserRelaysData(list: account.ionConnectRelays),
          ),
        )
        .toList();
    await ref.read(ionConnectDatabaseCacheProvider.notifier).saveAllEntities(relayEntities);
  }
}
