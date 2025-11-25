// SPDX-License-Identifier: ice License 1.0

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
  final Map<String, WalletsDatabase> _walletsDatabases = {};
  final Map<String, FollowingFeedDatabase> _followingFeedDatabases = {};
  final Map<String, BlockUserDatabase> _blockUserDatabases = {};
  final Map<String, NotificationsDatabase> _notificationsDatabases = {};
  final Map<String, ChatDatabase> _chatDatabases = {};
  final Map<String, OptimisticUiDatabase> _optimisticUiDatabases = {};

  Future<void> initializeDatabases({
    required String pubkey,
    String? appGroup,
  }) async {
    await closeAllDatabases();

    await _createWalletsDatabaseInternal(pubkey: pubkey, appGroup: appGroup);
    await _createFollowingFeedDatabaseInternal(pubkey: pubkey, appGroup: appGroup);
    await _createBlockUserDatabaseInternal(pubkey: pubkey, appGroup: appGroup);
    await _createOptimisticUiDatabaseInternal(pubkey: pubkey, appGroup: appGroup);
    await _createNotificationsDatabaseInternal(pubkey: pubkey, appGroup: appGroup);
    await _createChatDatabaseInternal(pubkey: pubkey, appGroup: appGroup);
  }

  Future<WalletsDatabase> _createWalletsDatabaseInternal({
    required String pubkey,
    String? appGroup,
  }) async {
    final db = WalletsDatabase(pubkey, appGroupId: appGroup);
    await db.customSelect('SELECT 1').getSingle();
    _walletsDatabases[pubkey] = db;

    return db;
  }

  Future<FollowingFeedDatabase> _createFollowingFeedDatabaseInternal({
    required String pubkey,
    String? appGroup,
  }) async {
    final db = FollowingFeedDatabase(pubkey);
    await db.customSelect('SELECT 1').getSingle();
    _followingFeedDatabases[pubkey] = db;

    return db;
  }

  Future<BlockUserDatabase> _createBlockUserDatabaseInternal({
    required String pubkey,
    String? appGroup,
  }) async {
    final db = BlockUserDatabase(pubkey);
    await db.customSelect('SELECT 1').getSingle();
    _blockUserDatabases[pubkey] = db;

    return db;
  }

  Future<NotificationsDatabase> _createNotificationsDatabaseInternal({
    required String pubkey,
    String? appGroup,
  }) async {
    final db = NotificationsDatabase(pubkey);
    await db.customSelect('SELECT 1').getSingle();
    _notificationsDatabases[pubkey] = db;

    return db;
  }

  Future<ChatDatabase> _createChatDatabaseInternal({
    required String pubkey,
    String? appGroup,
  }) async {
    final db = ChatDatabase(pubkey, appGroupId: appGroup);
    await db.customSelect('SELECT 1').getSingle();
    _chatDatabases[pubkey] = db;

    return db;
  }

  Future<OptimisticUiDatabase> _createOptimisticUiDatabaseInternal({
    required String pubkey,
    String? appGroup,
  }) async {
    final db = OptimisticUiDatabase(pubkey);
    await db.customSelect('SELECT 1').getSingle();
    _optimisticUiDatabases[pubkey] = db;

    return db;
  }

  WalletsDatabase? getWalletsDatabase(String pubkey) {
    return _walletsDatabases[pubkey];
  }

  FollowingFeedDatabase? getFollowingFeedDatabase(String pubkey) {
    return _followingFeedDatabases[pubkey];
  }

  BlockUserDatabase? getBlockUserDatabase(String pubkey) {
    return _blockUserDatabases[pubkey];
  }

  NotificationsDatabase? getNotificationsDatabase(String pubkey) {
    return _notificationsDatabases[pubkey];
  }

  ChatDatabase? getChatDatabase(String pubkey) {
    return _chatDatabases[pubkey];
  }

  OptimisticUiDatabase? getOptimisticUiDatabase(String pubkey) {
    return _optimisticUiDatabases[pubkey];
  }

  Future<void> closeWalletsDatabase() async {
    for (final db in _walletsDatabases.values) {
      await db.close();
    }
  }

  Future<void> closeFollowingFeedDatabase() async {
    for (final db in _followingFeedDatabases.values) {
      await db.close();
    }
  }

  Future<void> closeBlockUserDatabase() async {
    for (final db in _blockUserDatabases.values) {
      await db.close();
    }
  }

  Future<void> closeNotificationsDatabase() async {
    for (final db in _notificationsDatabases.values) {
      await db.close();
    }
  }

  Future<void> closeChatDatabase() async {
    for (final db in _chatDatabases.values) {
      await db.close();
    }
  }

  Future<void> closeOptimisticUiDatabase() async {
    for (final db in _optimisticUiDatabases.values) {
      await db.close();
    }
  }

  Future<void> closeAllDatabases() async {
    await closeWalletsDatabase();
    await closeFollowingFeedDatabase();
    await closeBlockUserDatabase();
    await closeNotificationsDatabase();
    await closeChatDatabase();
    await closeOptimisticUiDatabase();
  }

  Future<void> dispose() async {
    await closeAllDatabases();
  }
}
