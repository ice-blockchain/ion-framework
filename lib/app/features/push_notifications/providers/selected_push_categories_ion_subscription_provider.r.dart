// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/model/related_token.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription_platform.f.dart';
import 'package:ion/app/features/push_notifications/providers/account_notification_set_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_messaging_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/firebase_messaging_token_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/relay_firebase_app_config_provider.m.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_buying_activity_request.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_request.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/tokens_global_stat_request.f.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/services/device_id/device_id.r.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_push_categories_ion_subscription_provider.r.g.dart';

/// Provides the current user push subscription based on:
/// * the selected push notification categories
/// * the user's followed accounts
/// * the user's accounts that user wants to receive notifications from
/// * the user's current device FCM token
@Riverpod(keepAlive: true)
class SelectedPushCategoriesIonSubscription extends _$SelectedPushCategoriesIonSubscription {
  @override
  Future<PushSubscriptionOwnData?> build() async {
    final relaysFirebaseConfig = await ref.watch(relayFirebaseAppConfigProvider.future);
    final fcmConfigured = await ref.watch(configureFirebaseMessagingProvider.future);

    if (relaysFirebaseConfig == null || !fcmConfigured) {
      return null;
    }

    final encryptedFcmToken =
        await _getEncryptedFcmToken(relayPubkey: relaysFirebaseConfig.relayPubkey);
    if (encryptedFcmToken == null) {
      return null;
    }

    return PushSubscriptionOwnData(
      deviceId: await ref.watch(deviceIdServiceProvider).get(),
      platform: PushSubscriptionPlatform.forPlatform(),
      relay: RelatedRelay(url: relaysFirebaseConfig.relayUrl),
      fcmToken: RelatedToken(value: encryptedFcmToken),
      filters: await _getFilters(),
    );
  }

  Future<String?> _getEncryptedFcmToken({required String relayPubkey}) async {
    final fcmToken = await ref.watch(firebaseMessagingTokenProvider.future);
    if (fcmToken == null) {
      return null;
    }

    Logger.log('FCM token: $fcmToken');

    final encryptedMessageService = await ref.watch(encryptedMessageServiceProvider.future);
    return encryptedMessageService.encryptMessage(fcmToken, publicKey: relayPubkey);
  }

  Future<List<RequestFilter>> _getFilters() async {
    final selectedPushCategories = ref.watch(selectedPushCategoriesProvider).enabledCategories;

    final categoryFilters = await Future.wait(
      selectedPushCategories.map(_buildFilterForCategory),
    );

    final filters = categoryFilters.nonNulls.expand<RequestFilter>((filters) => filters).toList();

    final messageFilter = _buildFilterForMessages(selectedPushCategories);
    if (messageFilter != null) {
      filters.add(messageFilter);
    }

    final accountsFilters =
        await _buildAccountsFilters(selectedPushCategories: selectedPushCategories);
    if (accountsFilters != null) {
      filters.addAll(accountsFilters);
    }

    return filters;
  }

  Future<List<RequestFilter>?> _buildFilterForCategory(PushNotificationCategory category) async {
    return switch (category) {
      PushNotificationCategory.mentionsAndReplies => _buildFilterForMentionsAndReplies(),
      PushNotificationCategory.reposts => _buildFilterForReposts(),
      PushNotificationCategory.likes => _buildFilterForLikes(),
      PushNotificationCategory.newFollowers => _buildFilterForNewFollowers(),
      PushNotificationCategory.creatorToken => _buildFilterForCreatorToken(),
      PushNotificationCategory.contentToken => _buildFilterForContentToken(),
      PushNotificationCategory.creatorTokenTrades => _buildFilterForCreatorTokenTrades(),
      PushNotificationCategory.contentTokenTrades => _buildFilterForContentTokenTrades(),
      // PushNotificationCategory.tokenUpdates => _buildFilterForTokenUpdates(),
      _ => null,
    };
  }

  List<RequestFilter> _buildFilterForMentionsAndReplies() {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [ModifiablePostEntity.kind, ArticleEntity.kind],
        tags: {
          '#p': [currentUserPubkey],
        },
      ),
    ];
  }

  List<RequestFilter> _buildFilterForReposts() {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [GenericRepostEntity.kind],
        tags: {
          '#p': [currentUserPubkey],
          '#k': [ModifiablePostEntity.kind.toString(), ArticleEntity.kind.toString()],
        },
      ),
      RequestFilter(
        kinds: const [RepostEntity.kind],
        tags: {
          '#p': [currentUserPubkey],
        },
      ),
      RequestFilter(
        kinds: const [ModifiablePostEntity.kind],
        tags: {
          '#Q': [
            [null, null, currentUserPubkey],
          ],
        },
      ),
      RequestFilter(
        kinds: const [PostEntity.kind],
        tags: {
          '#q': [
            [null, null, currentUserPubkey],
          ],
        },
      ),
    ];
  }

  List<RequestFilter> _buildFilterForLikes() {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [ReactionEntity.kind],
        tags: {
          '#p': [currentUserPubkey],
        },
      ),
    ];
  }

  List<RequestFilter> _buildFilterForNewFollowers() {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [FollowListEntity.kind],
        tags: {
          '#p': [currentUserPubkey],
        },
      ),
    ];
  }

  Future<List<RequestFilter>> _buildFilterForCreatorToken() async {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserFollowList = await ref.watch(currentUserFollowListProvider.future);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [CommunityTokenDefinitionEntity.kind],
        tags: {
          '#p': [currentUserPubkey, ...(currentUserFollowList?.masterPubkeys ?? [])],
          '#k': [UserMetadataEntity.kind.toString()],
          '#t': const [communityTokenActionTopic],
        },
      ),
    ];
  }

  Future<List<RequestFilter>> _buildFilterForContentToken() async {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserFollowList = await ref.watch(currentUserFollowListProvider.future);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [CommunityTokenDefinitionEntity.kind],
        tags: {
          '#p': [currentUserPubkey, ...(currentUserFollowList?.masterPubkeys ?? [])],
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

  Future<List<RequestFilter>> _buildFilterForCreatorTokenTrades() async {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    final tokenizedCommunitiesTransactionsAccounts =
        await _getTokenizedCommunitiesTransactionsAccounts();
    return [
      RequestFilter(
        kinds: const [CommunityTokenActionEntity.kind],
        tags: {
          '#p': [currentUserPubkey, ...(tokenizedCommunitiesTransactionsAccounts ?? [])],
          '#k': [UserMetadataEntity.kind.toString()],
          '#t': const [communityTokenActionTopic],
          '#tx_type': [CommunityTokenActionType.buy.name],
        },
      ),
    ];
  }

  Future<List<RequestFilter>> _buildFilterForContentTokenTrades() async {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    final tokenizedCommunitiesTransactionsAccounts =
        await _getTokenizedCommunitiesTransactionsAccounts();
    return [
      RequestFilter(
        kinds: const [CommunityTokenActionEntity.kind],
        tags: {
          '#p': [currentUserPubkey, ...(tokenizedCommunitiesTransactionsAccounts ?? [])],
          '#k': [
            PostEntity.kind.toString(),
            ModifiablePostEntity.kind.toString(),
            ArticleEntity.kind.toString(),
          ],
          '#t': const [communityTokenActionTopic],
          '#tx_type': [CommunityTokenActionType.buy.name],
        },
      ),
    ];
  }

  Future<List<String>?> _getTokenizedCommunitiesTransactionsAccounts() async {
    final accountNotificationSets =
        await ref.watch(currentUserAccountNotificationSetsProvider.future);
    final tokenizedCommunitiesTransactionsAccounts = accountNotificationSets
        .firstWhereOrNull(
          (accountNotificationSet) =>
              accountNotificationSet.data.type ==
              AccountNotificationSetType.tokenizedCommunitiesTransactions,
        )
        ?.data
        .userPubkeys;
    return tokenizedCommunitiesTransactionsAccounts;
  }

  // TODO[pushes] apply
  // ignore: unused_element
  Future<List<Object>> _buildFilterForTokenUpdates() async {
    final ionNotifier = ref.watch(ionConnectNotifierProvider.notifier);
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();

    final requests = [
      TokenBuyingActivityRequestData(
        params: TokenBuyingActivityRequestParams(authorMasterPubkey: currentUserPubkey),
      ),
      TokenPriceChangeRequestData(
        params: TokenPriceChangeRequestParams(
          token: ReplaceableEventReference(
            masterPubkey: currentUserPubkey,
            kind: CommunityTokenDefinitionEntity.kind,
          ),
          timeWindow: const Duration(minutes: 5),
          deltaPercentage: 10,
        ),
      ),
      const TokensGlobalStatRequestData(),
    ];

    final events = await Future.wait(requests.map(ionNotifier.sign));
    return events.map((event) => event.toJson().last as Object).toList();
  }

  RequestFilter? _buildFilterForMessages(List<PushNotificationCategory> categories) {
    final messageCategories = [
      PushNotificationCategory.directMessages,
      PushNotificationCategory.messagePaymentRequest,
      PushNotificationCategory.messagePaymentReceived,
    ];

    if (!categories.any(messageCategories.contains)) return null;

    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();

    return RequestFilter(
      kinds: const [IonConnectGiftWrapEntity.kind],
      tags: {
        '#k': [
          // direct messages
          if (categories.contains(PushNotificationCategory.directMessages))
            [ReplaceablePrivateDirectMessageEntity.kind.toString(), ''],
          if (categories.contains(PushNotificationCategory.directMessages))
            // Using doubled kind 7 filter to take only the reactions (skipping statuses).
            [
              PrivateMessageReactionEntity.kind.toString(),
              PrivateMessageReactionEntity.kind.toString(),
            ],

          // money request message
          if (categories.contains(PushNotificationCategory.messagePaymentRequest))
            [
              ReplaceablePrivateDirectMessageEntity.kind.toString(),
              FundsRequestEntity.kind.toString(),
            ],
          // money sent message
          if (categories.contains(PushNotificationCategory.messagePaymentReceived))
            [
              ReplaceablePrivateDirectMessageEntity.kind.toString(),
              WalletAssetEntity.kind.toString(),
            ],
        ],
        '#p': [currentUserPubkey],
      },
    );
  }

  Future<List<RequestFilter>?> _buildAccountsFilters({
    required List<PushNotificationCategory> selectedPushCategories,
  }) async {
    final accountNotificationSets =
        await ref.watch(currentUserAccountNotificationSetsProvider.future);
    final accountNotificationsEnabled =
        selectedPushCategories.contains(PushNotificationCategory.posts);
    const accountsRelatedCategories = [
      AccountNotificationSetType.articles,
      AccountNotificationSetType.posts,
      AccountNotificationSetType.videos,
      AccountNotificationSetType.stories,
    ];

    // Skip tokenized communities transactions category because it is handled
    // when building filters for creator token trades and content token trades categories
    return [
      for (final AccountNotificationSetEntity(:data) in accountNotificationSets)
        if (accountsRelatedCategories.contains(data.type) &&
            accountNotificationsEnabled &&
            data.userPubkeys.isNotEmpty)
          data.type.toUserNotificationType().toRequestFilter(masterPubkeys: data.userPubkeys),
    ];
  }
}
