// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/pages/components/header_action/header_action.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/context_menu_item.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/context_menu_item_divider.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/block_user_modal/block_user_modal.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_page.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileContextMenu extends HookConsumerWidget {
  const ProfileContextMenu({
    required this.pubkey,
    required this.closeSignal,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final MenuCloseSignal closeSignal;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.displayErrors(reportNotifierProvider);

    final closeMenuRef = useRef<CloseMenuCallback?>(null);
    useEffect(
      () {
        void listener() => closeMenuRef.value?.call(animate: false);

        closeSignal.addListener(listener);

        return () => closeSignal.removeListener(listener);
      },
      [closeSignal],
    );

    return OverlayMenu(
      menuBuilder: (closeMenu) {
        closeMenuRef.value = closeMenu;

        final menuItems = _buildMenuItems(
          context,
          ref,
          closeMenu,
        );
        return OverlayMenuContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: menuItems,
          ),
        );
      },
      child: HeaderAction(
        onPressed: () {},
        disabled: true,
        opacity: 1,
        backgroundColor: profileMode == ProfileMode.dark ? Colors.transparent : null,
        iconColor: profileMode == ProfileMode.dark ? context.theme.appColors.onPrimaryAccent : null,
        assetName: Assets.svg.iconMorePopup,
      ),
    );
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    VoidCallback closeMenu,
  ) {
    final isCurrentUser = ref.watch(isCurrentUserSelectorProvider(pubkey));

    if (isCurrentUser) {
      return [
        ContextMenuItem(
          label: context.i18n.button_share,
          iconAsset: Assets.svg.iconButtonShare,
          onPressed: () {
            closeMenu();
            ShareViaMessageModalRoute(
              eventReference: ReplaceableEventReference(
                masterPubkey: pubkey,
                kind: UserMetadataEntity.kind,
              ).encode(),
            ).push<void>(context);
          },
        ),
        const ContextMenuItemDivider(),
        ContextMenuItem(
          label: context.i18n.bookmarks_title,
          iconAsset: Assets.svg.iconBookmarks,
          onPressed: () {
            closeMenu();
            BookmarksRoute().push<void>(context);
          },
        ),
        const ContextMenuItemDivider(),
        ContextMenuItem(
          label: context.i18n.invite_friends_button,
          iconAsset: Assets.svg.iconButtonInvite,
          onPressed: () {
            closeMenu();
            InviteFriendsRoute().push<void>(context);
          },
        ),
        const ContextMenuItemDivider(),
        ContextMenuItem(
          label: context.i18n.settings_title,
          iconAsset: Assets.svg.iconProfileSettings,
          onPressed: () {
            closeMenu();
            SettingsRoute().push<void>(context);
          },
        ),
      ];
    } else {
      return [
        ContextMenuItem(
          label: context.i18n.button_share,
          iconAsset: Assets.svg.iconButtonShare,
          onPressed: () {
            closeMenu();
            ShareViaMessageModalRoute(
              eventReference: ReplaceableEventReference(
                masterPubkey: pubkey,
                kind: UserMetadataEntity.kind,
              ).encode(),
            ).push<void>(context);
          },
        ),
        const ContextMenuItemDivider(),
        _BlockUserMenuItem(masterPubkey: pubkey, closeMenu: closeMenu),
        const ContextMenuItemDivider(),
        ContextMenuItem(
          label: context.i18n.button_report,
          iconAsset: Assets.svg.iconReport,
          onPressed: () {
            closeMenu();
            ref.read(reportNotifierProvider.notifier).report(
                  ReportReason.user(
                    text: context.i18n.report_user_description,
                    pubkey: pubkey,
                  ),
                );
          },
        ),
      ];
    }
  }
}

class _BlockUserMenuItem extends ConsumerWidget {
  const _BlockUserMenuItem({
    required this.masterPubkey,
    required this.closeMenu,
  });

  final String masterPubkey;
  final VoidCallback closeMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked = ref.watch(isBlockedNotifierProvider(masterPubkey)).valueOrNull ?? false;

    return ContextMenuItem(
      label: isBlocked ? context.i18n.button_unblock : context.i18n.button_block,
      iconAsset: Assets.svg.iconBlockClose3,
      onPressed: () {
        closeMenu();
        if (!isBlocked) {
          showSimpleBottomSheet<void>(
            context: context,
            child: BlockUserModal(pubkey: masterPubkey),
          );
        } else {
          ref.read(toggleBlockNotifierProvider.notifier).toggle(masterPubkey);
        }
      },
    );
  }
}
