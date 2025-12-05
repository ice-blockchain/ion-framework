// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/hooks/use_hide_on_signal.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/components/shadow/svg_shadow.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/feed/data/models/delete/delete_confirmation_type.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/views/pages/entity_delete_confirmation_modal/entity_delete_confirmation_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class OwnEntityMenu extends HookConsumerWidget {
  const OwnEntityMenu({
    required this.eventReference,
    this.iconColor,
    this.onDelete,
    this.padding = EdgeInsets.zero,
    this.showShadow = false,
    this.iconSize,
    this.closeSignal,
    super.key,
  });

  static double get menuIconSize => 20.0.s;

  final EventReference eventReference;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onDelete;
  final bool showShadow;
  final double? iconSize;
  final OverlayMenuCloseSignal? closeSignal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

    if (entity == null ||
        (entity is! ModifiablePostEntity && entity is! PostEntity && entity is! ArticleEntity)) {
      return const SizedBox.shrink();
    }

    final icon = Assets.svg.iconMorePopup.icon(
      color: iconColor ?? context.theme.appColors.onTertiaryBackground,
      size: iconSize,
    );

    final closeMenuRef = useHideOnSignal(closeSignal);

    return OverlayMenu(
      menuBuilder: (closeMenu) {
        closeMenuRef?.value = closeMenu;

        return Column(
          children: [
            OverlayMenuContainer(
              child: Column(
                children: [
                  if (entity is ModifiablePostEntity && _isEntityEditable(entity)) ...[
                    OverlayMenuItem(
                      minWidth: 75.0.s,
                      label: context.i18n.button_edit,
                      icon: Assets.svg.iconEditLink.icon(
                        size: menuIconSize,
                        color: context.theme.appColors.quaternaryText,
                      ),
                      onPressed: () {
                        closeMenu();

                        final parentEvent = entity.data.parentEvent?.eventReference.encode();
                        final quotedEvent = entity.data.quotedEvent?.eventReference.encode();
                        final modifiedEvent = entity.toEventReference().encode();

                        if (parentEvent != null) {
                          EditReplyRoute(
                            parentEvent: parentEvent,
                            modifiedEvent: modifiedEvent,
                          ).push<void>(context);
                        } else if (quotedEvent != null) {
                          EditQuoteRoute(
                            quotedEvent: quotedEvent,
                            modifiedEvent: modifiedEvent,
                          ).push<void>(context);
                        } else if (parentEvent == null && quotedEvent == null) {
                          EditPostRoute(
                            modifiedEvent: modifiedEvent,
                          ).push<void>(context);
                        }
                      },
                    ),
                    const OverlayMenuItemSeparator(),
                  ],
                  if (entity is ArticleEntity && _isEntityEditable(entity)) ...[
                    OverlayMenuItem(
                      minWidth: 75.0.s,
                      label: context.i18n.button_edit,
                      icon: Assets.svg.iconEditLink.icon(
                        size: menuIconSize,
                        color: context.theme.appColors.quaternaryText,
                      ),
                      onPressed: () {
                        closeMenu();

                        final modifiedEvent = entity.toEventReference().encode();
                        EditArticleRoute(modifiedEvent: modifiedEvent).push<void>(context);
                      },
                    ),
                    const OverlayMenuItemSeparator(),
                  ],
                  OverlayMenuItem(
                    minWidth: 75.0.s,
                    label: context.i18n.post_menu_delete,
                    labelColor: context.theme.appColors.attentionRed,
                    icon: Assets.svg.iconBlockDelete.icon(
                      size: menuIconSize,
                      color: context.theme.appColors.attentionRed,
                    ),
                    onPressed: () async {
                      closeMenu();
                      final confirmed = await showSimpleBottomSheet<bool>(
                        context: context,
                        child: EntityDeleteConfirmationModal(
                          eventReference: eventReference,
                          deleteConfirmationType: _getDeleteConfirmationType(entity),
                        ),
                      );

                      if ((confirmed ?? false) && context.mounted) {
                        onDelete?.call();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
      child: Padding(
        padding: padding,
        child: showShadow ? SvgShadow(child: icon) : icon,
      ),
    );
  }

  DeleteConfirmationType _getDeleteConfirmationType(IonConnectEntity entity) {
    if (entity is ArticleEntity) {
      return DeleteConfirmationType.article;
    } else if (entity is ModifiablePostEntity && entity.data.hasVideo) {
      return DeleteConfirmationType.video;
    }
    return DeleteConfirmationType.post;
  }

  bool _isEntityEditable(IonConnectEntity entity) {
    return switch (entity) {
      final ModifiablePostEntity post =>
        post.data.editingEndedAt?.value.toDateTime.isAfter(DateTime.now()) ?? false,
      final ArticleEntity article =>
        article.data.editingEndedAt?.value.toDateTime.isAfter(DateTime.now()) ?? false,
      _ => false,
    };
  }
}
