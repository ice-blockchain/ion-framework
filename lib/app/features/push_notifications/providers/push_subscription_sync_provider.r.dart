// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/push_notifications/providers/push_subscription_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_ion_subscription_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_subscription_sync_provider.r.g.dart';

@Riverpod(keepAlive: true)
class PushSubscriptionSync extends _$PushSubscriptionSync {
  @override
  Future<void> build() async {
    final authState = await ref.watch(authProvider.future);

    if (!authState.isAuthenticated) {
      return;
    }

    final delegationComplete = await ref.watch(delegationCompleteProvider.future);

    if (!delegationComplete) {
      return;
    }

    final selectedCategoriesSubscription =
        await ref.watch(selectedPushCategoriesIonSubscriptionProvider.future);
    final publishedSubscription = await ref.read(currentUserPushSubscriptionProvider.future);

    if (selectedCategoriesSubscription != null &&
        selectedCategoriesSubscription != publishedSubscription?.data) {
      await ref.watch(ionConnectNotifierProvider.notifier).sendEntityData(
            selectedCategoriesSubscription,
            actionSource: ActionSourceRelayUrl(selectedCategoriesSubscription.relay.url),
          );
    }

    if (selectedCategoriesSubscription != null &&
        selectedCategoriesSubscription.filters.isEmpty &&
        publishedSubscription != null) {
      await _deleteSubscription(publishedSubscription);
    }
  }

  Future<void> _deleteSubscription(PushSubscriptionEntity entity) async {
    await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(
          DeletionRequest(
            events: [
              EventToDelete(
                eventReference: ImmutableEventReference(
                  masterPubkey: entity.masterPubkey,
                  eventId: entity.id,
                  kind: PushSubscriptionEntity.kind,
                ),
              ),
            ],
          ),
          cache: false,
        );
    ref.read(ionConnectCacheProvider.notifier).remove(entity.cacheKey);
  }
}
