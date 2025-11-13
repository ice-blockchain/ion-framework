// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';

part 'account_notifications_option.f.freezed.dart';

@freezed
class AccountNotificationsOption with _$AccountNotificationsOption implements OptimisticModel {
  const factory AccountNotificationsOption({
    required String userPubkey,
    required Set<UserNotificationsType> selected,
  }) = _AccountNotificationsOption;

  const AccountNotificationsOption._();

  @override
  String get optimisticId => userPubkey;
}
