// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/providers/community_admins_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class DeleteAdminModal extends ConsumerWidget {
  const DeleteAdminModal({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minSize = Size(56.0.s, 56.0.s);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.actionCreatepostDeleterole,
            title: context.i18n.channel_create_admin_type_remove_title,
            description: context.i18n.channel_create_admin_type_remove_desc,
          ),
        ),
        SizedBox(height: 30.0.s),
        ScreenSideOffset.small(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Button.compact(
                  type: ButtonType.outlined,
                  label: Text(context.i18n.button_cancel),
                  minimumSize: minSize,
                  onPressed: () => context.pop(false),
                ),
              ),
              SizedBox(
                width: 16.0.s,
              ),
              Expanded(
                child: Button.compact(
                  label: Text(context.i18n.button_delete),
                  minimumSize: minSize,
                  backgroundColor: context.theme.appColors.attentionRed,
                  onPressed: () {
                    ref.read(communityAdminsProvider.notifier).deleteAdmin(pubkey);
                    context.pop(true);
                  },
                ),
              ),
            ],
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
