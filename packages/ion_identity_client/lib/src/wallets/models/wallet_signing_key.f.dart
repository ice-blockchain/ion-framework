// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_signing_key.f.freezed.dart';
part 'wallet_signing_key.f.g.dart';

@freezed
class WalletSigningKey with _$WalletSigningKey {
  factory WalletSigningKey({
    required String scheme,
    required String curve,
    required String publicKey,
    required String id,
  }) = _WalletSigningKey;

  factory WalletSigningKey.fromJson(Map<String, dynamic> json) => _$WalletSigningKeyFromJson(json);
}
