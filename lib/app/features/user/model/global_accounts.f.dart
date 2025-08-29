// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_accounts.f.freezed.dart';
part 'global_accounts.f.g.dart';

@freezed
class GlobalAccounts with _$GlobalAccounts {
  const factory GlobalAccounts({
    required List<String> pubkeys,
  }) = _GlobalAccounts;

  factory GlobalAccounts.fromJson(Map<String, dynamic> json) => _$GlobalAccountsFromJson(json);
}
