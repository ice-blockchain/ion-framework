// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/cloud_storage/cloud_storage_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_stored_recovery_keys_names_provider.r.g.dart';

@riverpod
Future<Set<String>> cloudStoredRecoveryKeysNames(Ref ref) async {
  final cloudStorage = ref.watch(cloudStorageProvider);
  final files = await cloudStorage.listFilesPaths(directory: 'ion');
  return files.map((file) => file.split('/').last.split('.').first).toSet();
}

@riverpod
Future<bool> hasCurrentUserBackupInCloud(Ref ref) async {
  final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentIdentityKeyName == null) {
    return false;
  }

  try {
    final recoveryKeyNames = await ref.watch(cloudStoredRecoveryKeysNamesProvider.future);
    return recoveryKeyNames.contains(currentIdentityKeyName);
  } catch (e) {
    // handles cancel, permission denied, etc.
    Logger.error(e);
    return false;
  }
}
