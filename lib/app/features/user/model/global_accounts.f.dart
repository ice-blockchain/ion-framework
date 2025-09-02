// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';

part 'global_accounts.f.freezed.dart';
part 'global_accounts.f.g.dart';

@Freezed(toJson: false)
class GlobalAccountsData with _$GlobalAccountsData {
  const factory GlobalAccountsData({
    required List<GlobalAccount> list,
  }) = _GlobalAccountsData;

  factory GlobalAccountsData.fromJson(List<dynamic> json) =>
      _$GlobalAccountsDataFromJson({'list': json});
}

@Freezed(toJson: false)
class GlobalAccount with _$GlobalAccount {
  const factory GlobalAccount({
    required String masterPubKey,
    required List<UserRelay> ionConnectRelays,
  }) = _GlobalAccount;

  factory GlobalAccount.fromJson(Map<String, dynamic> json) => _$GlobalAccountFromJson(json);
}
