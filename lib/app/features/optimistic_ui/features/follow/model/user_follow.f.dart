// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

part 'user_follow.f.freezed.dart';

@freezed
class UserFollow with _$UserFollow implements OptimisticModel {
  const factory UserFollow({
    required String pubkey,
    required bool following,
  }) = _UserFollow;
  const UserFollow._();

  @override
  String get optimisticId => pubkey;
}
