// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/header/story_context_menu.dart';
import 'package:ion/generated/assets.gen.dart';

class HeaderActions extends ConsumerWidget {
  const HeaderActions({required this.post, super.key});

  final ModifiablePostEntity post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconMoreColor = context.theme.appColors.onPrimaryAccent;

    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
    final isCurrentUser = currentUserPubkey == post.masterPubkey;

    final closeButton = GestureDetector(
      onTap: context.pop,
      child: Assets.svg.iconSheetClose.icon(color: iconMoreColor),
    );

    if (post.isDeleted) {
      return closeButton;
    }

    return Row(
      children: [
        StoryContextMenu(
          pubkey: post.masterPubkey,
          post: post,
          isCurrentUser: isCurrentUser,
          child: Assets.svg.iconMoreStories.icon(color: iconMoreColor),
        ),
        SizedBox(width: 16.0.s),
        closeButton,
      ],
    );
  }
}
