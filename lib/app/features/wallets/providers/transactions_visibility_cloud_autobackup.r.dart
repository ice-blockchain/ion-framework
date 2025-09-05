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
  return TransactionsVisibilityCloudAutoBackup(ref: ref).startSub();
}

class TransactionsVisibilityCloudAutoBackup {
  TransactionsVisibilityCloudAutoBackup({
    required this.ref,
  });

  final Ref ref;

  StreamSubscription<dynamic> startSub() {
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
  }
}
