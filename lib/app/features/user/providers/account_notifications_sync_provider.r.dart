// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/model/content_type.dart';
import 'package:ion/app/features/feed/notifications/data/repository/account_notification_sync_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/content_repository.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/event_backfill_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notifications_sync_provider.r.g.dart';

@riverpod
class AccountNotificationsSync extends _$AccountNotificationsSync {
  Timer? _syncTimer;

  @override
  FutureOr<void> build() async {
    keepAliveWhenAuthenticated(ref);

    final authState = await ref.watch(authProvider.future);
    if (!authState.isAuthenticated) {
      return;
    }

    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return;
    }

    await _initializeSync();
    ref.onDispose(cancelAllSync);
  }

  void cancelAllSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _initializeSync() async {
    final syncInterval = _getSyncInterval();
    try {
      final lastSyncTime = await _getLastSyncTime();
      if (_shouldSyncImmediately(lastSyncTime, syncInterval)) {
        await _syncAndScheduleNext(syncInterval);
      } else {
        _scheduleDelayedSync(lastSyncTime!, syncInterval);
      }
    } catch (error) {
      // Fallback: schedule a retry
      _syncTimer = Timer(syncInterval, () async {
        await _initializeSync();
      });
    }
  }

  Duration _getSyncInterval() {
    return ref.read(envProvider.notifier).get<Duration>(
          EnvVariable.ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES,
        );
  }

  bool _shouldSyncImmediately(DateTime? lastSyncTime, Duration syncInterval) {
    if (lastSyncTime == null) return true;

    final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
    return timeSinceLastSync >= syncInterval;
  }

  void _scheduleDelayedSync(DateTime lastSyncTime, Duration syncInterval) {
    final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
    final remainingTime = syncInterval - timeSinceLastSync;

    _syncTimer = Timer(remainingTime, () async {
      await _syncAndScheduleNext(syncInterval);
    });
  }

  Future<void> _syncAndScheduleNext(Duration syncInterval) async {
    await _performSync();
    _setupPeriodicSync(syncInterval);
  }

  void _setupPeriodicSync(Duration interval) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) async {
      await _performSync();
    });
  }

  Future<DateTime?> _getLastSyncTime() async {
    final repository = ref.read(accountNotificationSyncRepositoryProvider);
    return repository.getLastSyncTime();
  }

  Future<void> _performSync() async {
    final authState = await ref.read(authProvider.future);
    if (!authState.isAuthenticated) {
      return;
    }

    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return;
    }

    final blockedUsersKeys = ref.watch(blockedUsersPubkeysSelectorProvider);

    final contentTypes = await _getUserSpecificContentTypes();
    if (contentTypes.isEmpty) {
      return;
    }

    final usersMap = await _getAllUsersFromNotificationSets(contentTypes);

    if (usersMap.isEmpty) {
      return;
    }

    for (final entry in usersMap.entries) {
      final contentType = entry.key;
      final users = entry.value;
      final notBlockedUsers = users.where((e) => !blockedUsersKeys.contains(e)).toList();

      if (notBlockedUsers.isEmpty) {
        continue;
      }

      await _syncContentTypeFromRelay(
        users: notBlockedUsers,
        contentType: contentType,
      );
    }
  }

  Future<List<UserNotificationsType>> _getUserSpecificContentTypes() async {
    final userSpecificTypes = <UserNotificationsType>[];
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return userSpecificTypes;
    }

    for (final type in [
      UserNotificationsType.posts,
      UserNotificationsType.stories,
      UserNotificationsType.articles,
      UserNotificationsType.videos,
    ]) {
      final setType = AccountNotificationSetType.fromUserNotificationType(type);
      if (setType == null) {
        continue;
      }

      final accountNotificationSet = await ref.read(
        ionConnectEntityProvider(
          eventReference: ReplaceableEventReference(
            masterPubkey: currentPubkey,
            kind: AccountNotificationSetEntity.kind,
            dTag: setType.dTagName,
          ),
        ).future,
      );

      if (accountNotificationSet is AccountNotificationSetEntity &&
          accountNotificationSet.data.userPubkeys.isNotEmpty) {
        userSpecificTypes.add(type);
      }
    }

    return userSpecificTypes;
  }

  Future<Map<UserNotificationsType, List<String>>> _getAllUsersFromNotificationSets(
    List<UserNotificationsType> contentTypes,
  ) async {
    final result = <UserNotificationsType, List<String>>{};
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return result;
    }

    for (final contentType in contentTypes) {
      final setType = AccountNotificationSetType.fromUserNotificationType(contentType);
      if (setType == null) {
        continue;
      }

      final accountNotificationSet = await ref.read(
        ionConnectEntityProvider(
          eventReference: ReplaceableEventReference(
            masterPubkey: currentPubkey,
            kind: AccountNotificationSetEntity.kind,
            dTag: setType.dTagName,
          ),
        ).future,
      );

      if (accountNotificationSet is AccountNotificationSetEntity) {
        final users = accountNotificationSet.data.userPubkeys;
        result[contentType] = users;
      }
    }

    return result;
  }

  Future<void> _syncContentTypeFromRelay({
    required List<String> users,
    required UserNotificationsType contentType,
  }) async {
    final repository = ref.read(accountNotificationSyncRepositoryProvider);

    final contentTypeEnum = switch (contentType) {
      UserNotificationsType.posts => ContentType.posts,
      UserNotificationsType.stories => ContentType.stories,
      UserNotificationsType.articles => ContentType.articles,
      UserNotificationsType.videos => ContentType.videos,
      UserNotificationsType.none => throw ArgumentError('Cannot convert none to content type'),
    };

    final syncState = await repository.getSyncState(contentTypeEnum);

    final callStartTime = DateTime.now();

    DateTime latestEventTimestamp;

    if (syncState != null) {
      latestEventTimestamp = syncState;
    } else {
      final setCreationTime = await _getNotificationSetCreationTime(contentType);
      latestEventTimestamp = setCreationTime != null
          ? DateTime.fromMicrosecondsSinceEpoch(setCreationTime)
          : callStartTime;
    }

    final requestFilter = _buildRequestFilter(
      contentType: contentType,
      users: users,
    );

    if (requestFilter == null) {
      return;
    }

    final eventBackfillService = ref.read(eventBackfillServiceProvider);

    final eventFutures = <Future<void>>[];

    final newLastCreatedAt = await eventBackfillService.startBackfill(
      latestEventTimestamp: latestEventTimestamp.microsecondsSinceEpoch,
      filter: requestFilter,
      onEvent: (event) {
        eventFutures.add(_processNotificationEvent(event, contentType));
      },
      actionSource: ActionSourceOptimalRelays(
        masterPubkeys: users,
        strategy: OptimalRelaysStrategy.bestLatency,
      ),
    );

    await Future.wait(eventFutures);

    final actualNewTimestamp = DateTime.fromMicrosecondsSinceEpoch(newLastCreatedAt);

    await repository.updateSyncState(contentTypeEnum, actualNewTimestamp);
  }

  Future<int?> _getNotificationSetCreationTime(UserNotificationsType contentType) async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) return null;

    final setType = AccountNotificationSetType.fromUserNotificationType(contentType);
    if (setType == null) return null;

    final notificationSet = await ref.read(
      ionConnectEntityProvider(
        eventReference: ReplaceableEventReference(
          masterPubkey: currentPubkey,
          kind: AccountNotificationSetEntity.kind,
          dTag: setType.dTagName,
        ),
      ).future,
    );

    return notificationSet is AccountNotificationSetEntity ? notificationSet.createdAt : null;
  }

  RequestFilter? _buildRequestFilter({
    required UserNotificationsType contentType,
    required List<String> users,
  }) {
    if (users.isEmpty || contentType == UserNotificationsType.none) {
      return null;
    }

    return switch (contentType) {
      UserNotificationsType.videos => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: VideosSearchExtension(contain: true).query,
          authors: users,
          limit: 100,
        ),
      UserNotificationsType.stories => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: ExpirationSearchExtension(expiration: true).query,
          authors: users,
          limit: 100,
        ),
      UserNotificationsType.articles => RequestFilter(
          kinds: const [
            ArticleEntity.kind,
          ],
          authors: users,
          limit: 100,
        ),
      UserNotificationsType.posts => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: SearchExtensions([
            ExpirationSearchExtension(expiration: false),
            VideosSearchExtension(contain: false),
            TagMarkerSearchExtension(
              tagName: RelatedReplaceableEvent.tagName,
              marker: RelatedEventMarker.reply.name,
              negative: true,
            ),
          ]).toString(),
          authors: users,
          limit: 100,
        ),
      UserNotificationsType.none => throw ArgumentError('Cannot build filter for none type'),
    };
  }

  Future<void> _processNotificationEvent(
    EventMessage event,
    UserNotificationsType contentType,
  ) async {
    final entity = _convertEventToEntity(event);
    if (entity == null) {
      return;
    }

    await _saveToNotificationsDatabase(entity);
  }

  IonConnectEntity? _convertEventToEntity(EventMessage event) {
    final entity = ref.read(eventParserProvider).parse(event);
    return entity;
  }

  Future<void> _saveToNotificationsDatabase(IonConnectEntity entity) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    await contentRepo.save(entity);
  }
}
