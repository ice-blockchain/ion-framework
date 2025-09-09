// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/providers/transactions_visibility_cloud_backup.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_visibility_cloud_autobackup.r.g.dart';

@Riverpod(keepAlive: true)
StreamSubscription<dynamic> transactionsVisibilityCloudAutoBackup(
  Ref ref,
) {
  final transactionsVisibilityCloudAutoBackup = TransactionsVisibilityCloudAutoBackup(
    visibilityDao: ref.watch(transactionsVisibilityStatusDaoProvider),
    visibilityCloudBackup: ref.watch(transactionsVisibilityCloudBackupProvider),
  );

  final sub = transactionsVisibilityCloudAutoBackup.startSub();

  ref.onDispose(() {
    transactionsVisibilityCloudAutoBackup.cancel();
    sub.cancel();
  });

  return sub;
}

class TransactionsVisibilityCloudAutoBackup {
  TransactionsVisibilityCloudAutoBackup({
    required this.visibilityDao,
    required this.visibilityCloudBackup,
  });

  final TransactionsVisibilityStatusDao visibilityDao;
  final TransactionsVisibilityCloudBackup visibilityCloudBackup;

  Timer? debounce;

  StreamSubscription<dynamic> startSub() {
    var lastSeenCount = 0;

    final sub = visibilityDao
        .select(visibilityDao.transactionVisibilityStatusTable)
        .watch()
        .listen((rows) async {
      // Only backup if the number of seen entries actually changed
      final seenCount = rows.where((r) => r.status == TransactionVisibilityStatus.seen).length;
      if (seenCount != lastSeenCount) {
        lastSeenCount = seenCount;

        // Debounce to avoid multiple rapid uploads
        debounce?.cancel();
        debounce = Timer(const Duration(seconds: 2), () async {
          await visibilityCloudBackup.backupAll();
        });
      }
    });

    return sub;
  }

  void cancel() {
    debounce?.cancel();
    debounce = null;
  }
}
