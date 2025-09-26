// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/protect_account/backup/providers/cloud_stored_recovery_keys_names_provider.r.dart';
import 'package:ion/app/features/protect_account/backup/providers/create_recovery_key_action_notifier.r.dart';
import 'package:ion/app/features/protect_account/backup/views/components/backup_option.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/cloud_storage/cloud_storage_service.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class CloudBackupOption extends HookConsumerWidget {
  const CloudBackupOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..displayErrors(
        createRecoveryKeyActionNotifierProvider,
        excludedExceptions: excludedPasskeyExceptions,
      )
      ..listenSuccess(createRecoveryKeyActionNotifierProvider, (recoveryCredentials) {
        if (recoveryCredentials != null && context.mounted) {
          BackupWithCloudRoute().push<void>(context);
        }
      });

    final storedRecoveryKeysProvider = ref.watch(cloudStoredRecoveryKeysNamesProvider);

    final locale = context.i18n;
    return BackupOption(
      title: locale.backup_option_with(
        Platform.isIOS ? locale.backup_icloud : locale.backup_google_drive,
      ),
      subtitle: locale.backup_option_cloud_description,
      icon: Assets.svg.walletLoginCloud.icon(
        size: 48.0.s,
      ),
      isOptionEnabled: storedRecoveryKeysProvider.valueOrNull?.isNotEmpty ?? false,
      isLoading: storedRecoveryKeysProvider.isLoading,
      onTap: () async {
        final cloudAvailable = await ref.read(cloudStorageProvider).isAvailable();
        if (!context.mounted) return;
        if (!cloudAvailable) {
          await BackupWithCloudDisabledRoute().push<void>(context);
        } else {
          await guardPasskeyDialog(
            context,
            (child) => RiverpodVerifyIdentityRequestBuilder(
              provider: createRecoveryKeyActionNotifierProvider,
              requestWithVerifyIdentity: (OnVerifyIdentity<CredentialResponse> onVerifyIdentity) {
                ref
                    .read(createRecoveryKeyActionNotifierProvider.notifier)
                    .createRecoveryCredentials(onVerifyIdentity);
              },
              child: child,
            ),
          );
        }
      },
    );
  }
}
