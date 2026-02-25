// SPDX-License-Identifier: ice License 1.0

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
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/model/related_token.f.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription_platform.f.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_messaging_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/firebase_messaging_token_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/relay_firebase_app_config_provider.m.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_provider.m.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/services/device_id/device_id.r.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_push_categories_ion_subscription_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SelectedPushCategoriesIonSubscription extends _$SelectedPushCategoriesIonSubscription {
  @override
  Future<PushSubscriptionData?> build() async {
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

    return PushSubscriptionData(
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

    final filters = selectedPushCategories
        .map(_buildFilterForCategory)
        .nonNulls
        .expand<RequestFilter>((filters) => filters)
        .toList();

    final encryptedFilter = _buildFilterForEncryptedEvents(selectedPushCategories);
    if (encryptedFilter != null) {
      filters.add(encryptedFilter);
    }

    return filters;
  }

  List<RequestFilter>? _buildFilterForCategory(PushNotificationCategory category) {
    return switch (category) {
      PushNotificationCategory.mentionsAndReplies => _buildFilterForMentionsAndReplies(),
      PushNotificationCategory.reposts => _buildFilterForReposts(),
      PushNotificationCategory.likes => _buildFilterForLikes(),
      PushNotificationCategory.newFollowers => _buildFilterForNewFollowers(),
      PushNotificationCategory.messagePaymentReceived => _buildFilterForPaymentReceived(),
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

  /// Handling encrypted categories all together since they are combined
  /// into a single filter (they all are encrypted with gift wraps).
  RequestFilter? _buildFilterForEncryptedEvents(List<PushNotificationCategory> categories) {
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

  /// Alongside the encrypted [WalletAssetEntity.kind] events, we also need to listen for
  /// unencrypted ones.
  ///
  /// Encrypted ones are produced when transaction is made from within the app.
  /// Unencrypted ones are produced by BE when transaction is made from
  ///   outside of the app (e.g., from an external wallet).
  List<RequestFilter> _buildFilterForPaymentReceived() {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserPubkey == null) throw UserMasterPubkeyNotFoundException();
    return [
      RequestFilter(
        kinds: const [WalletAssetEntity.kind],
        tags: {
          '#p': [currentUserPubkey],
        },
      ),
    ];
  }
}
