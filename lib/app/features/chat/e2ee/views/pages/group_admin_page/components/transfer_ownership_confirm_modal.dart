// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/update_group_metadata_service.r.dart';
import 'package:ion/generated/assets.gen.dart';

class TransferOwnershipConfirmModal extends ConsumerWidget {
  const TransferOwnershipConfirmModal({
    required this.conversationId,
    required this.newOwnerMasterPubkey,
    required this.currentOwnerMasterPubkey,
    super.key,
  });

  final String conversationId;
  final String newOwnerMasterPubkey;
  final String currentOwnerMasterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonMinimalSize = Size(56.0.s, 56.0.s);

    return SimpleModalSheet.alert(
      iconAsset: Assets.svg.actionCreatepostDeleterole,
      title: context.i18n.transfer_group_ownership_title,
      description: context.i18n.transfer_group_ownership_desc,
      button: ScreenSideOffset.small(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Button.compact(
                label: Text(context.i18n.change_owner),
                onPressed: () {
                  ref.read(updateGroupMetaDataServiceProvider).transferOwnership(
                        groupId: conversationId,
                        newOwnerMasterPubkey: newOwnerMasterPubkey,
                        currentOwnerMasterPubkey: currentOwnerMasterPubkey,
                      );
                  context.pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context.maybePop();
                    }
                  });
                },
                minimumSize: buttonMinimalSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
