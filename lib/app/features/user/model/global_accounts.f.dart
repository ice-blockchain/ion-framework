// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';

part 'global_accounts.f.freezed.dart';
part 'global_accounts.f.g.dart';

@Freezed(toJson: false)
class GlobalAccounts with _$GlobalAccounts {
  const factory GlobalAccounts({
    required List<GlobalAccount> accounts,
  }) = _GlobalAccounts;

  factory GlobalAccounts.fromJson(List<dynamic> json) =>
      _$GlobalAccountsFromJson({'accounts': json});
}

@Freezed(toJson: false)
class GlobalAccount with _$GlobalAccount {
  const factory GlobalAccount({
    required String masterPubKey,
    required List<UserRelay> ionConnectRelays,
  }) = _GlobalAccount;

  factory GlobalAccount.fromJson(Map<String, dynamic> json) => _$GlobalAccountFromJson(json);
}
