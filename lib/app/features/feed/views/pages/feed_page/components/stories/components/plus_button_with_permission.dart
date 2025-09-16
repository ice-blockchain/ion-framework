// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_sheets.dart';
import 'package:ion/app/features/feed/nft/sync/nft_collection_sync_controller.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/plus_icon.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class PlusButtonWithPermission extends ConsumerWidget {
  const PlusButtonWithPermission({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plusSize = 24.0.s;
    final iconPosition = 16.0.s;

    return PositionedDirectional(
      bottom: iconPosition,
      child: PermissionAwareWidget(
        permissionType: Permission.camera,
        requestId: 'story_record',
        onGrantedPredicate: () =>
            GoRouter.of(context).state.fullPath?.startsWith(FeedRoute().location) ?? false,
        onGranted: () => _onPlusButtonPressed(context, ref),
        requestDialog: const PermissionRequestSheet(permission: Permission.camera),
        settingsDialog: SettingsRedirectSheet.fromType(context, Permission.camera),
        builder: (context, onPressed) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 4.0.s),
              child: PlusIcon(size: plusSize),
            ),
          );
        },
      ),
    );
  }

  void _onPlusButtonPressed(BuildContext context, WidgetRef ref) {
    final hasNftCollectionState = ref.read(hasIonContentNftCollectionProvider).value;

    if (hasNftCollectionState case final hasNftCollection? when hasNftCollection) {
      StoryRecordRoute().push<void>(context);
    } else {
      FeedContentCreationBlockedModalRoute().push<void>(context);
    }
  }
}
