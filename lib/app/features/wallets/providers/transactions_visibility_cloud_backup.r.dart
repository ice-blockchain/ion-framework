// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/services/cloud_storage/cloud_storage_service.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';

final transactionsVisibilityCloudBackupProvider =
    Provider<TransactionsVisibilityCloudBackup>((ref) {
  return TransactionsVisibilityCloudBackup(
    ref: ref,
    cloud: ref.watch(cloudStorageProvider),
    visibilityDao: ref.watch(transactionsVisibilityStatusDaoProvider),
  );
});

/// On Ios we backup the visibility status to the cloud
/// On Android we don't cause we don't want to show user googleauth screen
/// So, on Android we just mark all as seen
class TransactionsVisibilityCloudBackup {
  TransactionsVisibilityCloudBackup({
    required this.ref,
    required this.cloud,
    required this.visibilityDao,
  });

  final Ref ref;
  final CloudStorageService cloud;
  final TransactionsVisibilityStatusDao visibilityDao;

  String _filePath({required String pubkey}) => 'wallets/$pubkey/visibility_seen_v1.sql';

  Future<void> backupAll() async {
    if (!Platform.isIOS) return;

    if (!await cloud.isAvailable()) return;
    final pubkey = ref.read(currentPubkeySelectorProvider);
    if (pubkey == null) return;

    final pairs = await visibilityDao.getSeenPairs();

    final buffer = StringBuffer();
    for (final p in pairs) {
      buffer.writeln(
        "INSERT OR REPLACE INTO transaction_visibility_status_table (tx_hash, wallet_view_id, status) VALUES ('${_esc(p.txHash)}', '${_esc(p.walletViewId)}', 1);",
      );
    }

    await cloud.uploadFile(_filePath(pubkey: pubkey), buffer.toString());
  }

  Future<void> restoreAll() async {
    final pubkey = ref.read(currentPubkeySelectorProvider);
    if (pubkey == null) return;

    // Check if already restored for this pubkey
    final localStorage = ref.read(localStorageProvider);
    final restoredKey = 'transactions_visibility_restored_$pubkey';
    final alreadyRestored = localStorage.getBool(restoredKey) ?? false;

    if (alreadyRestored) return;

    if (!Platform.isIOS) {
      await visibilityDao.transaction(() async {
        await visibilityDao
            .customStatement('UPDATE transaction_visibility_status_table SET status = 1;');
      });

      await localStorage.setBool(key: restoredKey, value: true);

      return;
    }

    if (!await cloud.isAvailable()) return;

    final content = await cloud.downloadFile(_filePath(pubkey: pubkey));
    if (content == null || content.isEmpty) return;

    await visibilityDao.transaction(() async {
      final statements = content.split(';');
      for (final raw in statements) {
        final stmt = raw.trim();
        if (stmt.isEmpty) continue;
        await visibilityDao.customStatement('$stmt;');
      }
    });

    // Mark as restored for this pubkey
    await localStorage.setBool(key: restoredKey, value: true);
  }

  String _esc(String s) => s.replaceAll("'", "''");
}

final transactionsVisibilityCloudAutoBackupProvider = Provider<StreamSubscription<dynamic>>((ref) {
  final dao = ref.watch(transactionsVisibilityStatusDaoProvider);
  Timer? debounce;
  var lastSeenCount = 0;

  final sub = dao.select(dao.transactionVisibilityStatusTable).watch().listen((rows) async {
    // Only backup if the number of seen entries actually changed
    final seenCount = rows.where((r) => r.status == TransactionVisibilityStatus.seen).length;
    if (seenCount != lastSeenCount) {
      lastSeenCount = seenCount;

      // Debounce to avoid multiple rapid uploads
      debounce?.cancel();
      debounce = Timer(const Duration(seconds: 2), () async {
        await ref.read(transactionsVisibilityCloudBackupProvider).backupAll();
      });
    }
  });

  ref.onDispose(() {
    debounce?.cancel();
    sub.cancel();
  });
  return sub;
});
