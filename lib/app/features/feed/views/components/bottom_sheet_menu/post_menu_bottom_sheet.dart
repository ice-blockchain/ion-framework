// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_content.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_header_button.dart';
import 'package:ion/app/components/icons/outlined_icon.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/unfollow_user_page.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/boosted_posts_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/block_user_modal/block_user_modal.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class PostMenuBottomSheet extends ConsumerWidget {
  const PostMenuBottomSheet({
    required this.eventReference,
    this.reportTitle,
    this.showNotInterested = true,
    super.key,
  });

  final EventReference eventReference;
  final String? reportTitle;
  final bool showNotInterested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(
      userPreviewDataProvider(eventReference.masterPubkey, network: false)
          .select(userPreviewNameSelector),
    );
    final isArticle = eventReference is ReplaceableEventReference &&
        (eventReference as ReplaceableEventReference).kind == ArticleEntity.kind;

    ref.displayErrors(reportNotifierProvider);

    final encoded = eventReference.encode();
    final boostedState = ref.watch(boostedPostsProvider);
    final isBoosted = boostedState.maybeWhen(
      data: (ids) => ids.contains(encoded),
      orElse: () => false,
    );

    final menuItemsGroups = <List<Widget>>[];
    final menuItemsFollowGroup = <Widget>[];
    final menuItemsComplainGroup = <Widget>[];

    // Follow/Unfollow menu item
    menuItemsFollowGroup.add(
      _FollowUserMenuItem(
        pubkey: eventReference.masterPubkey,
        username: username,
      ),
    );

    menuItemsGroups.add(menuItemsFollowGroup);

    // Not Interested menu item
    if (showNotInterested) {
      menuItemsComplainGroup.add(
        _NotInterestedMenuItem(
          pubkey: eventReference.masterPubkey,
        ),
      );
    }
    // Block/Unblock menu item
    menuItemsComplainGroup
      ..add(
        _BlockUserMenuItem(
          pubkey: eventReference.masterPubkey,
          username: username,
          onBlocked: context.canPop() ? context.pop : null,
        ),
      )
      ..add(
        ListItem(
          onTap: () {
            Navigator.of(context).pop();
            ref.read(reportNotifierProvider.notifier).report(
                  ReportReason.content(
                    text: context.i18n.report_content_description,
                    eventReference: eventReference,
                  ),
                );
          },
          leading: OutlinedIcon(
            icon: Assets.svg.iconReport.icon(
              size: 20.0.s,
              color: context.theme.appColors.attentionRed,
            ),
          ),
          title: Text(
            isArticle
                ? context.i18n.article_menu_report_article
                : context.i18n.post_menu_report_post,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
      );

    menuItemsGroups.add(menuItemsComplainGroup);

    final headerButtons = <Widget>[
      BottomSheetMenuHeaderButton(
        label: context.i18n.button_boost,
        iconAsset: Assets.svg.iconSheetBoost,
        onPressed: () {
          Navigator.of(context).pop();
          if (isBoosted) {
            ActiveBoostPostModalRoute(eventReference: encoded).push<void>(context);
          } else {
            NewBoostPostModalRoute(eventReference: encoded).push<void>(context);
          }
        },
      ),
      BottomSheetMenuHeaderButton(
        label: context.i18n.button_tip_creator,
        iconAsset: Assets.svg.iconProfileTips,
        onPressed: () {
          Navigator.of(context).pop();
          // TODO: Implement tip functionality
        },
      ),
    ];

    return BottomSheetMenuContent(
      groups: menuItemsGroups,
      headerButtons: headerButtons,
    );
  }
}

class _FollowUserMenuItem extends ConsumerWidget {
  const _FollowUserMenuItem({
    required this.pubkey,
    required this.username,
  });

  final String pubkey;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.displayErrors(toggleFollowNotifierProvider);
    final following = ref.watch(isCurrentUserFollowingSelectorProvider(pubkey));
    return ListItem(
      onTap: () {
        Navigator.of(context).pop();
        if (following) {
          showSimpleBottomSheet<void>(
            context: context,
            child: UnfollowUserModal(pubkey: pubkey),
          );
        } else {
          ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
        }
      },
      leading: OutlinedIcon(
        icon: Assets.svg.iconFollowuser.icon(
          size: 20.0.s,
          color: context.theme.appColors.primaryAccent,
        ),
      ),
      title: Text(
        following
            ? context.i18n.post_menu_unfollow_nickname(username)
            : context.i18n.post_menu_follow_nickname(username),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

class _BlockUserMenuItem extends ConsumerWidget {
  const _BlockUserMenuItem({
    required this.pubkey,
    required this.username,
    this.onBlocked,
  });

  final String pubkey;
  final String username;
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked = ref.watch(isBlockedNotifierProvider(pubkey)).valueOrNull ?? false;
    return ListItem(
      onTap: () async {
        Navigator.of(context).pop();
        if (!isBlocked) {
          final confirmed = await showSimpleBottomSheet<bool>(
            context: context,
            child: BlockUserModal(pubkey: pubkey),
          );
          if (confirmed ?? false) {
            onBlocked?.call();
          }
        } else {
          unawaited(ref.read(toggleBlockNotifierProvider.notifier).toggle(pubkey));
        }
      },
      leading: OutlinedIcon(
        icon: Assets.svg.iconBlock.icon(
          size: 20.0.s,
          color: context.theme.appColors.attentionRed,
        ),
      ),
      title: Text(
        isBlocked
            ? context.i18n.post_menu_unblock_nickname(username)
            : context.i18n.post_menu_block_nickname(username),
        style: context.theme.appTextThemes.body.copyWith(
          color: context.theme.appColors.primaryText,
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

class _NotInterestedMenuItem extends ConsumerWidget {
  const _NotInterestedMenuItem({
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListItem(
      onTap: () {
        Navigator.of(context).pop();
        ref.read(mutedUsersProvider.notifier).toggleMutedMasterPubkey(pubkey);
      },
      leading: OutlinedIcon(
        icon: Assets.svg.iconNotinterested.icon(
          size: 20.0.s,
          color: context.theme.appColors.primaryAccent,
        ),
      ),
      title: Text(context.i18n.post_menu_not_interested),
      backgroundColor: Colors.transparent,
    );
  }
}
