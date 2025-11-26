// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/following_feed_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/optimistic_ui/database/optimistic_ui_database.m.dart';
import 'package:ion/app/features/user_block/model/database/block_user_database.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_manager_service.r.g.dart';

@Riverpod(keepAlive: true)
DatabaseManagerService databaseManagerService(Ref ref) {
  final service = DatabaseManagerService();
  ref.onDispose(service.dispose);
  return service;
}

class DatabaseManagerService {
  DatabaseManagerService() {
    _walletsStore = _DatabaseStore<WalletsDatabase>(
      (pubkey, appGroup) => WalletsDatabase(pubkey, appGroupId: appGroup),
    );
    _followingFeedStore = _DatabaseStore<FollowingFeedDatabase>(
      (pubkey, _) => FollowingFeedDatabase(pubkey),
    );
    _blockUserStore = _DatabaseStore<BlockUserDatabase>(
      (pubkey, _) => BlockUserDatabase(pubkey),
    );
    _notificationsStore = _DatabaseStore<NotificationsDatabase>(
      (pubkey, _) => NotificationsDatabase(pubkey),
    );
    _chatStore = _DatabaseStore<ChatDatabase>(
      (pubkey, appGroup) => ChatDatabase(pubkey, appGroupId: appGroup),
    );
    _optimisticUiStore = _DatabaseStore<OptimisticUiDatabase>(
      (pubkey, _) => OptimisticUiDatabase(pubkey),
    );
  }

  late final _DatabaseStore<WalletsDatabase> _walletsStore;
  late final _DatabaseStore<FollowingFeedDatabase> _followingFeedStore;
  late final _DatabaseStore<BlockUserDatabase> _blockUserStore;
  late final _DatabaseStore<NotificationsDatabase> _notificationsStore;
  late final _DatabaseStore<ChatDatabase> _chatStore;
  late final _DatabaseStore<OptimisticUiDatabase> _optimisticUiStore;

  Future<void> initializeDatabases({
    required String pubkey,
    String? appGroup,
  }) async {
    await closeAllDatabases();

    await Future.wait([
      _walletsStore.createAndStore(pubkey, appGroup),
      _followingFeedStore.createAndStore(pubkey, appGroup),
      _blockUserStore.createAndStore(pubkey, appGroup),
      _notificationsStore.createAndStore(pubkey, appGroup),
      _chatStore.createAndStore(pubkey, appGroup),
      _optimisticUiStore.createAndStore(pubkey, appGroup),
    ]);
  }

  Future<void> closeAllDatabases() async {
    await Future.wait([
      _walletsStore.closeAll(),
      _followingFeedStore.closeAll(),
      _blockUserStore.closeAll(),
      _notificationsStore.closeAll(),
      _chatStore.closeAll(),
      _optimisticUiStore.closeAll(),
    ]);
  }

  Future<void> dispose() async {
    await closeAllDatabases();
  }

  // NOTE(ice-linus): Get database by pubkey

  WalletsDatabase? getWalletsDatabase(String pubkey) {
    return _walletsStore.get(pubkey);
  }

  FollowingFeedDatabase? getFollowingFeedDatabase(String pubkey) {
    return _followingFeedStore.get(pubkey);
  }

  BlockUserDatabase? getBlockUserDatabase(String pubkey) {
    return _blockUserStore.get(pubkey);
  }

  NotificationsDatabase? getNotificationsDatabase(String pubkey) {
    return _notificationsStore.get(pubkey);
  }

  ChatDatabase? getChatDatabase(String pubkey) {
    return _chatStore.get(pubkey);
  }

  OptimisticUiDatabase? getOptimisticUiDatabase(String pubkey) {
    return _optimisticUiStore.get(pubkey);
  }

  // NOTE(ice-linus): Close database

  Future<void> closeWalletsDatabase() async {
    await _walletsStore.closeAll();
  }

  Future<void> closeFollowingFeedDatabase() async {
    await _followingFeedStore.closeAll();
  }

  Future<void> closeBlockUserDatabase() async {
    await _blockUserStore.closeAll();
  }

  Future<void> closeNotificationsDatabase() async {
    await _notificationsStore.closeAll();
  }

  Future<void> closeChatDatabase() async {
    await _chatStore.closeAll();
  }

  Future<void> closeOptimisticUiDatabase() async {
    await _optimisticUiStore.closeAll();
  }
}

class _DatabaseStore<T extends GeneratedDatabase> {
  _DatabaseStore(this._factory);

  final Map<String, T> _databases = {};
  final T Function(String pubkey, String? appGroup) _factory;

  Future<void> createAndStore(String pubkey, String? appGroup) async {
    final db = _factory(pubkey, appGroup);
    await db.customSelect('SELECT 1').getSingle();
    _databases[pubkey] = db;
  }

  T? get(String pubkey) {
    return _databases[pubkey];
  }

  Future<void> closeAll() async {
    for (final db in _databases.values) {
      await db.close();
    }
  }
}
