// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/push_notifications/providers/account_notification_set_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_push_subscription_service_provider.r.g.dart';

class AccountsPushSubscriptionService {
  AccountsPushSubscriptionService({
    required UserRelaysEntity currentUserRelays,
    required IonConnectNotifier ionConnectNotifier,
    required Future<IonConnectEntity?> Function({required EventReference eventReference})
        getIonConnectEntity,
    required Future<List<PushNotificationCategory>> Function() getSelectedPushCategories,
    required Future<List<AccountNotificationSetEntity>> Function()
        getCurrentUserAccountNotificationSets,
  })  : _currentUserRelays = currentUserRelays,
        _ionConnectNotifier = ionConnectNotifier,
        _getIonConnectEntity = getIonConnectEntity,
        _getSelectedPushCategories = getSelectedPushCategories,
        _getCurrentUserAccountNotificationSets = getCurrentUserAccountNotificationSets;

  final Future<IonConnectEntity?> Function({required EventReference eventReference})
      _getIonConnectEntity;

  final Future<List<PushNotificationCategory>> Function() _getSelectedPushCategories;

  final Future<List<AccountNotificationSetEntity>> Function()
      _getCurrentUserAccountNotificationSets;

  final UserRelaysEntity _currentUserRelays;

  final IonConnectNotifier _ionConnectNotifier;

  /// Updates the external user push subscription when the current user
  /// changes their account notification settings for a specific user.
  Future<void> updateOnAccountSettingsChange({
    required String masterPubkey,
    required AccountNotificationSetType notificationSetType,
    required bool shouldIncludeUser,
  }) async {
    if (!await _isAccountPushesEnabled()) {
      return;
    }

    final currentFilters = await _getUserSubscriptionFilters(masterPubkey: masterPubkey);

    final notificationType = notificationSetType.toUserNotificationType();

    if (shouldIncludeUser) {
      final contains = currentFilters
          .any((filter) => UserNotificationsType.fromFilter(filter) == notificationType);
      if (contains) {
        return;
      }
      final updatedFilters = [
        ...currentFilters,
        notificationType.toRequestFilter(authors: [masterPubkey]),
      ];

      await _sendUpdatedPushSubscriptionExternalData(
        masterPubkey: masterPubkey,
        filters: updatedFilters,
      );
    } else {
      if (currentFilters.isEmpty) {
        return;
      }

      final updatedFilters = currentFilters.where((filter) {
        final type = UserNotificationsType.fromFilter(filter);
        return type != notificationType;
      }).toList();

      if (updatedFilters.length == currentFilters.length) {
        return;
      }

      if (updatedFilters.isEmpty) {
        await _deletePushSubscriptionExternalData(masterPubkey: masterPubkey);
      } else {
        await _sendUpdatedPushSubscriptionExternalData(
          masterPubkey: masterPubkey,
          filters: updatedFilters,
        );
      }
    }
  }

  /// Updates the external user push subscription when the a user is followed or unfollowed.
  ///
  /// If a user is unfollowed, the push subscription for that user is removed entirely.
  /// If a user is followed, a new push subscription is created for that user,
  ///   based on the current notification settings - if categories that depend on followed users are enabled.
  ///   And based the current account notification sets of the followed user - user could be followed,
  ///   account notifications are enabled, then unfollowed and followed again.
  Future<void> updateOnFollowToggle({
    required String masterPubkey,
    required bool following,
  }) async {
    // If we unfollow a user, we remove the push subscription entirely
    if (!following) {
      final currentFilters = await _getUserSubscriptionFilters(masterPubkey: masterPubkey);
      if (currentFilters.isNotEmpty) {
        await _deletePushSubscriptionExternalData(masterPubkey: masterPubkey);
      }
      return;
    } else {
      // User was not followed before, so it can not have a current subscription, building from scratch
      final filters = <RequestFilter>[];

      // If account pushes are enabled, building filters based on the current notification sets for the user
      if (await _isAccountPushesEnabled()) {
        final currentUserAccountNotificationSets = await _getCurrentUserAccountNotificationSets();
        final followedUserSets = currentUserAccountNotificationSets
            .where((notificationSet) => notificationSet.data.userPubkeys.contains(masterPubkey));
        filters.addAll(
          followedUserSets.map(
            (notificationSet) => notificationSet.data.type.toUserNotificationType().toRequestFilter(
              authors: [masterPubkey],
            ),
          ),
        );
      }

      // If categories that depend on followed users are enabled, add the corresponding filters
      final selectedPushCategories = await _getSelectedPushCategories();
      if (selectedPushCategories.contains(PushNotificationCategory.creatorToken)) {
        filters.addAll(await _buildFilterForCreatorToken(masterPubkey: masterPubkey));
      }
      if (selectedPushCategories.contains(PushNotificationCategory.contentToken)) {
        filters.addAll(await _buildFilterForContentToken(masterPubkey: masterPubkey));
      }

      if (filters.isNotEmpty) {
        await _sendUpdatedPushSubscriptionExternalData(
          masterPubkey: masterPubkey,
          filters: filters,
        );
      }
    }
  }

  // call on
  // 1. change in push notification settings
  Future<void> updateFollowedUsersSubscriptions() async {
    // get current follow list

    // get current 30000 sets (check the pubkey in each set), build filters upon it
    // get current subscription categories (check if categories for follow list are on, check is posts is on)
    // compare with the current subscription, if not eq, send to relay
  }

  Future<List<RequestFilter>> _getUserSubscriptionFilters({
    required String masterPubkey,
  }) async {
    final pushSubscriptionReference = _buildPushSubscriptionEventReference(masterPubkey);

    final currentSubscriptionEntity =
        await _getIonConnectEntity(eventReference: pushSubscriptionReference);

    final currentFilters = switch (currentSubscriptionEntity) {
      PushSubscriptionEntity() => currentSubscriptionEntity.data.filters,
      _ => <RequestFilter>[],
    };

    return currentFilters;
  }

  Future<void> _sendUpdatedPushSubscriptionExternalData({
    required String masterPubkey,
    required List<RequestFilter> filters,
  }) async {
    final pushSubscription = PushSubscriptionExternalData(
      externalUserMasterPubkey: masterPubkey,
      filters: filters,
      relays: _currentUserRelays.urls.map((url) => RelatedRelay(url: url)).toList(),
    );

    await _ionConnectNotifier.sendEntityData(
      pushSubscription,
      actionSource: ActionSourceUser(masterPubkey),
      cache: false,
    );
  }

  Future<void> _deletePushSubscriptionExternalData({
    required String masterPubkey,
  }) async {
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: _buildPushSubscriptionEventReference(masterPubkey),
        ),
      ],
    );
    await _ionConnectNotifier.sendEntityData(deletionRequest, cache: false);
  }

  EventReference _buildPushSubscriptionEventReference(String masterPubkey) {
    return ReplaceableEventReference(
      masterPubkey: masterPubkey,
      kind: PushSubscriptionEntity.kind,
      dTag: masterPubkey,
    );
  }

  Future<bool> _isAccountPushesEnabled() async {
    final selectedCategories = await _getSelectedPushCategories();
    final postsCategory = selectedCategories
        .firstWhereOrNull((category) => category == PushNotificationCategory.posts);
    return postsCategory != null;
  }

  Future<List<RequestFilter>> _buildFilterForCreatorToken({required String masterPubkey}) async {
    return [
      RequestFilter(
        kinds: const [CommunityTokenDefinitionEntity.kind],
        tags: {
          '#p': [masterPubkey],
          '#k': [UserMetadataEntity.kind.toString()],
          '#t': const [communityTokenActionTopic],
        },
      ),
    ];
  }

  Future<List<RequestFilter>> _buildFilterForContentToken({required String masterPubkey}) async {
    return [
      RequestFilter(
        kinds: const [CommunityTokenDefinitionEntity.kind],
        tags: {
          '#p': [masterPubkey],
          '#k': [
            PostEntity.kind.toString(),
            ModifiablePostEntity.kind.toString(),
            ArticleEntity.kind.toString(),
          ],
          '#t': const [communityTokenActionTopic],
        },
      ),
    ];
  }
}

@Riverpod(keepAlive: true)
Future<AccountsPushSubscriptionService> accountsPushSubscriptionService(Ref ref) async {
  Future<IonConnectEntity?> getIonConnectEntity({required EventReference eventReference}) async =>
      ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
  Future<List<PushNotificationCategory>> getSelectedPushCategories() async =>
      ref.read(selectedPushCategoriesProvider).enabledCategories;
  Future<List<AccountNotificationSetEntity>> getCurrentUserAccountNotificationSets() async =>
      ref.read(currentUserAccountNotificationSetsProvider.future);
  final currentUserRelays = await ref.watch(currentUserRelaysProvider.future);
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  if (currentUserRelays == null) {
    throw UserRelaysNotFoundException();
  }

  return AccountsPushSubscriptionService(
    currentUserRelays: currentUserRelays,
    ionConnectNotifier: ionConnectNotifier,
    getIonConnectEntity: getIonConnectEntity,
    getSelectedPushCategories: getSelectedPushCategories,
    getCurrentUserAccountNotificationSets: getCurrentUserAccountNotificationSets,
  );
}
