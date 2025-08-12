// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/settings/optimistic_ui/model/who_can_message_privacy_option.f.dart';
import 'package:ion/app/features/settings/optimistic_ui/who_can_message_sync_strategy.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'who_can_message_sync_strategy_provider.r.g.dart';

@riverpod
SyncStrategy<WhoCanMessagePrivacyOption> whoCanMessageSyncStrategy(Ref ref) {
  return WhoCanMessageStrategy(
    updateVisibility: (visibility) async {
      final userMetadata = ref.read(currentUserMetadataProvider).valueOrNull;
      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

      if (currentUserMasterPubkey == null) {
        throw UserMasterPubkeyNotFoundException();
      }

      if (userMetadata == null) {
        throw UserMetadataNotFoundException(currentUserMasterPubkey);
      }

      final updatedMetadata =
          userMetadata.data.copyWith(whoCanMessageYou: visibility.toWhoCanSetting());

      await ref.read(updateUserMetadataNotifierProvider.notifier).publish(updatedMetadata);
    },
  );
}
