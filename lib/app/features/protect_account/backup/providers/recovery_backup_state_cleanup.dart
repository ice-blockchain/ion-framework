// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/protect_account/backup/providers/cloud_stored_recovery_keys_names_provider.r.dart';
import 'package:ion/app/features/protect_account/backup/providers/recovery_key_cloud_backup_delete_notifier.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/recovery_keys_completed_provider.r.dart';

Future<void> cleanupBackupStateAfterRecovery(
  WidgetRef ref, {
  required String identityKeyName,
}) async {
  await ref.read(recoveryKeysCompletedProvider.notifier).clearCompleted(
        identityKeyName: identityKeyName,
      );

  ref
    ..invalidate(cloudStoredRecoveryKeysNamesProvider)
    ..invalidate(hasCurrentUserBackupInCloudProvider);

  unawaited(
    ref.read(recoveryKeyCloudBackupDeleteNotifierProvider.notifier).remove(
          identityKeyName: identityKeyName,
        ),
  );
}
