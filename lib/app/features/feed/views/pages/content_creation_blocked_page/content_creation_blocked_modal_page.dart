// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
import 'package:ion/app/features/feed/nft/sync/nft_collection_sync_controller.r.dart';
import 'package:ion/app/features/feed/views/components/content_creation_blocked_modal/content_creation_blocked_modal.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class FeedContentCreationBlockedModalPage extends HookConsumerWidget {
  const FeedContentCreationBlockedModalPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNftCollectionState = ref.watch(hasIonContentNftCollectionProvider);

    useEffect(
      () {
        hasNftCollectionState.whenOrNull(
          data: (hasNfts) {
            if (hasNfts && context.mounted) {
              context.pop();
              StoryRecordRoute().push<void>(context);
            }
          },
        );
        return;
      },
      [hasNftCollectionState],
    );

    return SheetContent(
      backgroundColor: context.theme.appColors.secondaryBackground,
      topPadding: 0.0.s,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: hasNftCollectionState.when(
          data: (hasContentNftCollection) => const ContentCreationBlockedModal(),
          loading: () => const CreateContentLoadingModal(),
          error: (error, __) => ErrorModal(error: error),
        ),
      ),
    );
  }
}
