// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/account_notification_sync_time_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/content_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/token_launch_repository.r.dart';
import 'package:ion/app/features/feed/notifications/providers/batched_sync_service_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/push_notifications/providers/account_notification_set_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notifications_sync_provider.r.g.dart';

class AccountNotificationsSyncService {
  AccountNotificationsSyncService({
    required Duration syncInterval,
    required AccountNotificationSyncTimeRepository syncTimeRepository,
    required BatchedSyncService batchedSyncService,
    required AccountNotificationsEventsHandler? notificationsEventsHandler,
    required Future<List<AccountNotificationSetEntity>> Function()
        getCurrentUserAccountNotificationSets,
    required Future<FollowListEntity?> Function() getCurrentUserFollowList,
    required List<String> Function() getBlockedUsersPubkeys,
  })  : _syncInterval = syncInterval,
        _syncTimeRepository = syncTimeRepository,
        _batchedSyncService = batchedSyncService,
        _notificationsEventsHandler = notificationsEventsHandler,
        _getCurrentUserAccountNotificationSets = getCurrentUserAccountNotificationSets,
        _getCurrentUserFollowList = getCurrentUserFollowList,
        _getBlockedUsersPubkeys = getBlockedUsersPubkeys;

  final Duration _syncInterval;
  final AccountNotificationSyncTimeRepository _syncTimeRepository;
  final BatchedSyncService _batchedSyncService;
  final AccountNotificationsEventsHandler? _notificationsEventsHandler;
  final Future<List<AccountNotificationSetEntity>> Function()
      _getCurrentUserAccountNotificationSets;
  final Future<FollowListEntity?> Function() _getCurrentUserFollowList;
  final List<String> Function() _getBlockedUsersPubkeys;

  Timer? _syncTimer;

  /// Indicates whether a sync operation is currently in progress to prevent overlapping syncs.
  bool _isSyncing = false;

  /// Indicates whether the sync process has been cancelled to prevent scheduling new syncs or processing events.
  bool _isCancelled = false;

  void cancelAllSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isCancelled = true;
    _batchedSyncService.cancel();
  }

  Future<void> initializeSync() async {
    _isCancelled = false;
    _batchedSyncService.reset();

    try {
      var lastSyncTime = await _getLastSyncTime();
      if (lastSyncTime == null) {
        lastSyncTime = DateTime.now();
        await _setLastSyncTime(syncTime: lastSyncTime);
      }

      if (_shouldSyncImmediately(lastSyncTime)) {
        await _syncAndScheduleNext();
      } else {
        _scheduleDelayedSync(lastSyncTime);
      }
    } catch (error) {
      _syncTimer = Timer(_syncInterval, initializeSync);
    }
  }

  bool _shouldSyncImmediately(DateTime? lastSyncTime) {
    if (lastSyncTime == null) return true;

    final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
    return timeSinceLastSync >= _syncInterval;
  }

  void _scheduleDelayedSync(DateTime lastSyncTime) {
    final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
    final remainingTime = _syncInterval - timeSinceLastSync;

    _syncTimer = Timer(remainingTime, _syncAndScheduleNext);
  }

  Future<void> _syncAndScheduleNext() async {
    await performSync();
    _setupPeriodicSync();
  }

  void _setupPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await performSync();
    });
  }

  Future<DateTime?> _getLastSyncTime() async {
    return _syncTimeRepository.getLastSyncTime();
  }

  Future<void> _setLastSyncTime({required DateTime syncTime}) async {
    return _syncTimeRepository.setLastSyncTime(syncTime);
  }

  Future<void> performSync() async {
    if (_isSyncing || _isCancelled) {
      return;
    }

    _isSyncing = true;
    try {
      final lastSyncTime = await _getLastSyncTime();

      if (lastSyncTime == null) {
        await _setLastSyncTime(syncTime: DateTime.now());
        return;
      }

      await Future.wait([
        _syncFollowedUsersNotifications(lastSyncTime: lastSyncTime),
        _syncAccountsNotifications(lastSyncTime: lastSyncTime),
      ]);

      if (!_isCancelled) {
        await _setLastSyncTime(syncTime: DateTime.now());
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncFollowedUsersNotifications({required DateTime lastSyncTime}) async {
    final currentUserFollowList = await _getCurrentUserFollowList();
    if (currentUserFollowList == null) throw FollowListNotFoundException();

    final followedUsersPubkeys = currentUserFollowList.masterPubkeys;
    if (followedUsersPubkeys.isEmpty || _isCancelled) {
      return;
    }

    final eventFutures = <Future<void>>[];
    await _batchedSyncService.performSync(
      masterPubkeys: followedUsersPubkeys,
      filterBuilder: _buildTokenLaunchRequestFilter,
      lastSyncTime: lastSyncTime,
      syncInterval: _syncInterval,
      onEvent: (event) async {
        if (!_isCancelled) {
          eventFutures.add(_processNotificationEvent(event));
        }
      },
    );

    if (!_isCancelled) {
      await Future.wait(eventFutures);
    }
  }

  Future<List<void>> _syncAccountsNotifications({required DateTime lastSyncTime}) async {
    final accountNotifications = await _getInterestedAccountNotifications();
    final syncFutures = [
      for (final MapEntry(key: notificationType, value: masterPubkeys)
          in accountNotifications.entries)
        _syncNotificationType(
          masterPubkeys: masterPubkeys,
          notificationType: notificationType,
          lastSyncTime: lastSyncTime,
        ),
    ];
    return Future.wait(syncFutures);
  }

  Future<Map<UserNotificationsType, List<String>>> _getInterestedAccountNotifications() async {
    final currentUserAccountNotificationSets = await _getCurrentUserAccountNotificationSets();

    final currentUserFollowList = await _getCurrentUserFollowList();
    if (currentUserFollowList == null) throw FollowListNotFoundException();

    final followedUsersPubkeys = currentUserFollowList.masterPubkeys.toSet();
    final blockedUsersPubkeys = _getBlockedUsersPubkeys().toSet();

    return {
      for (final notificationSet in currentUserAccountNotificationSets)
        notificationSet.data.type.toUserNotificationType(): notificationSet.data.userPubkeys
            .where(
              (String userPubkey) =>
                  followedUsersPubkeys.contains(userPubkey) &&
                  !blockedUsersPubkeys.contains(userPubkey),
            )
            .toList(),
    }..removeWhere((_, users) => users.isEmpty);
  }

  Future<void> _syncNotificationType({
    required List<String> masterPubkeys,
    required UserNotificationsType notificationType,
    required DateTime lastSyncTime,
  }) async {
    if (masterPubkeys.isEmpty || _isCancelled) {
      return;
    }

    final eventFutures = <Future<void>>[];

    await _batchedSyncService.performSync(
      masterPubkeys: masterPubkeys,
      filterBuilder: ({required List<String> masterPubkeys}) => _buildAccountRequestFilter(
        notificationType: notificationType,
        masterPubkeys: masterPubkeys,
      ),
      lastSyncTime: lastSyncTime,
      syncInterval: _syncInterval,
      onEvent: (event) {
        if (!_isCancelled) {
          eventFutures.add(_processNotificationEvent(event));
        }
      },
    );

    if (!_isCancelled) {
      await Future.wait(eventFutures);
    }
  }

  RequestFilter _buildAccountRequestFilter({
    required UserNotificationsType notificationType,
    required List<String> masterPubkeys,
  }) {
    return notificationType.toRequestFilter(masterPubkeys: masterPubkeys);
  }

  RequestFilter _buildTokenLaunchRequestFilter({
    required List<String> masterPubkeys,
  }) {
    return RequestFilter(
      kinds: const [CommunityTokenDefinitionEntity.kind],
      tags: {
        '#p': masterPubkeys,
        '#t': const [communityTokenActionTopic],
      },
    );
  }

  Future<void> _processNotificationEvent(EventMessage event) async {
    await _notificationsEventsHandler?.handle(event);
  }
}

@riverpod
class AccountNotificationsSync extends _$AccountNotificationsSync {
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

    final syncTimeRepository = ref.watch(accountNotificationSyncTimeRepositoryProvider);
    if (syncTimeRepository == null) {
      return;
    }

    final service = AccountNotificationsSyncService(
      syncInterval: ref.watch(envProvider.notifier).get<Duration>(
            EnvVariable.ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES,
          ),
      syncTimeRepository: syncTimeRepository,
      notificationsEventsHandler: ref.watch(accountNotificationsEventsHandlerProvider),
      batchedSyncService: ref.watch(batchedSyncServiceProvider),
      getCurrentUserAccountNotificationSets: () =>
          ref.read(currentUserAccountNotificationSetsProvider.future),
      getCurrentUserFollowList: () => ref.read(currentUserFollowListProvider.future),
      getBlockedUsersPubkeys: () => ref.read(blockedUsersPubkeysSelectorProvider).toList(),
    );

    unawaited(service.initializeSync());
    ref.onDispose(service.cancelAllSync);
  }
}

class AccountNotificationsEventsHandler {
  AccountNotificationsEventsHandler({
    required TokenLaunchRepository tokenLaunchRepository,
    required ContentRepository contentRepository,
    required EventParser eventParser,
    required String currentMasterPubkey,
  })  : _tokenLaunchRepository = tokenLaunchRepository,
        _contentRepository = contentRepository,
        _eventParser = eventParser,
        _currentMasterPubkey = currentMasterPubkey;

  final TokenLaunchRepository _tokenLaunchRepository;
  final ContentRepository _contentRepository;
  final EventParser _eventParser;
  final String _currentMasterPubkey;

  Future<void> handle(EventMessage eventMessage) async {
    final entity = _eventParser.parse(eventMessage);
    if (eventMessage.kind == CommunityTokenDefinitionEntity.kind) {
      if (entity.masterPubkey == _currentMasterPubkey) {
        return;
      }
      await _tokenLaunchRepository.save(entity);
    } else {
      await _contentRepository.save(entity);
    }
  }
}

@riverpod
AccountNotificationsEventsHandler? accountNotificationsEventsHandler(Ref ref) {
  final currentMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentMasterPubkey == null) {
    return null;
  }

  return AccountNotificationsEventsHandler(
    tokenLaunchRepository: ref.watch(tokenLaunchRepositoryProvider),
    contentRepository: ref.watch(contentRepositoryProvider),
    eventParser: ref.watch(eventParserProvider),
    currentMasterPubkey: currentMasterPubkey,
  );
}
