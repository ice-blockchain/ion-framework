// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/ion_identity.dart';

part 'global_accounts.f.freezed.dart';
part 'global_accounts.f.g.dart';

@Freezed(toJson: false)
class GlobalAccountsData with _$GlobalAccountsData {
  const factory GlobalAccountsData({
    required List<IdentityUserInfo> list,
  }) = _GlobalAccountsData;

  factory GlobalAccountsData.fromJson(List<dynamic> json) =>
      _$GlobalAccountsDataFromJson({'list': json});
}
