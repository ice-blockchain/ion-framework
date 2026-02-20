// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notification_set_provider.r.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserAccountNotificationSets extends _$CurrentUserAccountNotificationSets {
  @override
  Future<List<AccountNotificationSetEntity>> build() async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) return [];

    final delegationComplete = await ref.watch(delegationCompleteProvider.future);
    if (!delegationComplete) return [];

    final fetches = <Future<AccountNotificationSetEntity?>>[];
    for (final contentType in UserNotificationsType.values) {
      final setType = AccountNotificationSetType.fromUserNotificationType(contentType);
      if (setType == null) continue;
      fetches.add(() async {
        final accountNotificationSet = await ref.watch(
          ionConnectEntityProvider(
            eventReference: ReplaceableEventReference(
              masterPubkey: currentPubkey,
              kind: AccountNotificationSetEntity.kind,
              dTag: setType.dTagName,
            ),
          ).future,
        );

        if (accountNotificationSet is AccountNotificationSetEntity) {
          return accountNotificationSet;
        }
        return null;
      }());
    }

    final accountNotificationSets = await Future.wait(fetches);

    return accountNotificationSets.nonNulls.toList();
  }
}
