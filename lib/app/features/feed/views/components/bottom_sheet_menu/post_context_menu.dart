// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/own_post_menu_bottom_sheet.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/post_menu_bottom_sheet.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';

class PostContextMenu extends ConsumerWidget {
  const PostContextMenu({
    required this.eventReference,
    required this.entity,
    this.isAccentTheme = false,
    this.onDelete,
    this.showNotInterested = true,
    this.showShadow = false,
    this.iconColor,
    this.padding,
    this.forAppBar = false,
    super.key,
  });

  const PostContextMenu.forAppBar({
    required EventReference eventReference,
    required IonConnectEntity? entity,
    VoidCallback? onDelete,
    Color? iconColor,
    bool showShadow = true,
    Key? key,
  }) : this(
          eventReference: eventReference,
          entity: entity,
          onDelete: onDelete,
          iconColor: iconColor,
          showShadow: showShadow,
          forAppBar: true,
          key: key,
        );

  final EventReference eventReference;
  final IonConnectEntity? entity;
  final bool isAccentTheme;
  final VoidCallback? onDelete;
  final bool showNotInterested;
  final bool showShadow;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final bool forAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entity == null) {
      return const SizedBox.shrink();
    }

    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));
    final hasFirstBuy = _hasFirstBuy(ref, isOwnedByCurrentUser, entity);
    final isEditable = switch (entity) {
      final ModifiablePostEntity post =>
        post.data.editingEndedAt?.value.toDateTime.isAfter(DateTime.now()) ?? false,
      final ArticleEntity _ => true,
      _ => false,
    };
    final shouldShowMenuButton = !isOwnedByCurrentUser || !(hasFirstBuy && !isEditable);

    if (!shouldShowMenuButton) {
      return const SizedBox.shrink();
    }

    final menuButton = BottomSheetMenuButton(
      menuBuilder: (context) => isOwnedByCurrentUser
          ? OwnPostMenuBottomSheet(
              eventReference: eventReference,
              onDelete: onDelete,
            )
          : PostMenuBottomSheet(
              eventReference: eventReference,
              showNotInterested: showNotInterested,
            ),
      isAccentTheme: isAccentTheme,
      showShadow: showShadow,
      iconColor: iconColor,
      padding: padding ??
          EdgeInsetsGeometry.symmetric(
            horizontal: ScreenSideOffset.defaultSmallMargin,
            vertical: 5.0.s,
          ),
    );

    if (forAppBar) {
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 6.0.s),
        child: menuButton,
      );
    }

    return menuButton;
  }

  bool _hasFirstBuy(
    WidgetRef ref,
    bool isOwnedByCurrentUser,
    IonConnectEntity? entity,
  ) {
    if (!isOwnedByCurrentUser || entity == null) return false;
    final eventReference = entity.toEventReference();
    return ref
            .watch(
              ionConnectEntityHasTokenProvider(eventReference: eventReference),
            )
            .valueOrNull ??
        false;
  }
}
