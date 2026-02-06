// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/push_notifications/providers/account_notification_set_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_push_subscription_service_provider.r.g.dart';

/// Service responsible for managing the external user push subscriptions.
///
/// Because when we need to receive pushes about some user,
/// we need to create a push subscription (31751 event) with the filters for that user and
/// publish it to the relays of that user.
class AccountsPushSubscriptionService {
  AccountsPushSubscriptionService({
    required UserRelaysEntity currentUserRelays,
    required Future<IonConnectEntity?> Function({required EventReference eventReference})
        getIonConnectEntity,
    required Future<List<PushNotificationCategory>> Function() getSelectedPushCategories,
    required Future<List<AccountNotificationSetEntity>> Function()
        getCurrentUserAccountNotificationSets,
  })  : _currentUserRelays = currentUserRelays,
        _getIonConnectEntity = getIonConnectEntity,
        _getSelectedPushCategories = getSelectedPushCategories,
        _getCurrentUserAccountNotificationSets = getCurrentUserAccountNotificationSets;
  final Future<IonConnectEntity?> Function({required EventReference eventReference})
      _getIonConnectEntity;

  final Future<List<PushNotificationCategory>> Function() _getSelectedPushCategories;

  final Future<List<AccountNotificationSetEntity>> Function()
      _getCurrentUserAccountNotificationSets;

  final UserRelaysEntity _currentUserRelays;

  /// Builds the account push subscription when the a user is followed.
  ///
  /// A push subscription is created, based on:
  ///   * The current account notification sets of the followed user - user could be followed,
  ///       account notifications are enabled, then unfollowed and followed again.
  ///   * The current notification settings - if categories that depend on followed users are enabled.
  Future<EventSerializable?> buildSubscriptionForFollowedUser({
    required String masterPubkey,
  }) async {
    final filters = <RequestFilter>[];

    // If account pushes are enabled, building filters based on the current notification sets for the user
    if (await _isAccountPushesEnabled()) {
      final currentUserAccountNotificationSets = await _getCurrentUserAccountNotificationSets();
      final followedUserSets = currentUserAccountNotificationSets
          .where((notificationSet) => notificationSet.data.userPubkeys.contains(masterPubkey));
      filters.addAll(
        followedUserSets.map(
          (notificationSet) => notificationSet.data.type.toUserNotificationType().toRequestFilter(
            masterPubkeys: [masterPubkey],
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
      return _buildPushSubscriptionExternalData(
        masterPubkey: masterPubkey,
        filters: filters,
      );
    } else {
      return _buildDeletePushSubscriptionExternalData(masterPubkey: masterPubkey);
    }
  }

  /// If we unfollow a user, we remove the push subscription entirely.
  Future<EventSerializable?> buildSubscriptionForUnfollowedUser({
    required String masterPubkey,
  }) async {
    final currentFilters = await _getUserSubscriptionFilters(masterPubkey: masterPubkey);
    if (currentFilters.isNotEmpty) {
      return _buildDeletePushSubscriptionExternalData(masterPubkey: masterPubkey);
    }
    return null;
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

  Future<EventSerializable> _buildPushSubscriptionExternalData({
    required String masterPubkey,
    required List<RequestFilter> filters,
  }) async {
    return PushSubscriptionExternalData(
      externalUserMasterPubkey: masterPubkey,
      filters: filters,
      relays: _currentUserRelays.urls.map((url) => RelatedRelay(url: url)).toList(),
    );
  }

  Future<EventSerializable> _buildDeletePushSubscriptionExternalData({
    required String masterPubkey,
  }) async {
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: _buildPushSubscriptionEventReference(masterPubkey),
        ),
      ],
    );
    return deletionRequest;
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
  if (currentUserRelays == null) {
    throw UserRelaysNotFoundException();
  }

  return AccountsPushSubscriptionService(
    currentUserRelays: currentUserRelays,
    getIonConnectEntity: getIonConnectEntity,
    getSelectedPushCategories: getSelectedPushCategories,
    getCurrentUserAccountNotificationSets: getCurrentUserAccountNotificationSets,
  );
}
