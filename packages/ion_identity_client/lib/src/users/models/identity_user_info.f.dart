// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/src/users/models/ion_connect_relay_info.f.dart';

part 'identity_user_info.f.freezed.dart';
part 'identity_user_info.f.g.dart';

@freezed
class IdentityUserInfo with _$IdentityUserInfo {
  const factory IdentityUserInfo({
    required String masterPubKey,
    required String username,
    required String displayName,
    required List<IonConnectRelayInfo> ionConnectRelays,
    String? avatar,
  }) = _IdentityUserInfo;

  const IdentityUserInfo._();

  factory IdentityUserInfo.fromJson(Map<String, dynamic> json) => _$IdentityUserInfoFromJson(json);

  String? get avatarUrl => avatar != null && avatar!.isNotEmpty ? avatar : null;
}
