// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/pages/components/header_action/header_action.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class CommunityTokenContextMenu extends HookConsumerWidget {
  const CommunityTokenContextMenu({
    required this.closeSignal,
    required this.tokenDefinitionEntity,
    super.key,
  });

  final OverlayMenuCloseSignal closeSignal;
  final CommunityTokenDefinitionEntity? tokenDefinitionEntity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.displayErrors(reportNotifierProvider);

    final closeMenuRef = useRef<CloseOverlayMenuCallback?>(null);
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

        return OverlayMenuContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OverlayMenuItem(
                verticalPadding: 12.s,
                label: context.i18n.button_share,
                icon: Assets.svg.iconButtonShare
                    .icon(size: 20.s, color: context.theme.appColors.quaternaryText),
                onPressed: () {
                  closeMenu();
                  if (tokenDefinitionEntity == null) return;
                  final eventReference = tokenDefinitionEntity!.toEventReference();
                  ShareViaMessageModalRoute(eventReference: eventReference.encode())
                      .push<void>(context);
                },
              ),
              const OverlayMenuItemSeparator(),
              OverlayMenuItem(
                verticalPadding: 12.s,
                label: context.i18n.button_report,
                icon: Assets.svg.iconReport
                    .icon(size: 20.s, color: context.theme.appColors.quaternaryText),
                onPressed: closeMenu,
              ),
            ],
          ),
        );
      },
      child: HeaderAction(
        onPressed: () {
          //TODO(ice-kreios) implement report action
        },
        disabled: true,
        opacity: 1,
        backgroundColor: Colors.transparent,
        iconColor: context.theme.appColors.onPrimaryAccent,
        assetName: Assets.svg.iconMorePopup,
      ),
    );
  }
}
