// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_content.dart';
import 'package:ion/app/components/icons/outlined_icon.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/delete/delete_confirmation_type.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/views/pages/entity_delete_confirmation_modal/entity_delete_confirmation_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class OwnPostMenuBottomSheet extends ConsumerWidget {
  const OwnPostMenuBottomSheet({
    required this.eventReference,
    this.onDelete,
    super.key,
  });

  final EventReference eventReference;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityAsync = ref.watch(ionConnectEntityProvider(eventReference: eventReference));
    if (entityAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final entity = entityAsync.valueOrNull;
    if (entity == null ||
        (entity is! ModifiablePostEntity && entity is! PostEntity && entity is! ArticleEntity)) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    final menuItemsGroups = <List<Widget>>[];
    final editMenuItems = <Widget>[];
    final deleteMenuItems = <Widget>[];

    final hasFirstBuy = ref
            .watch(
              ionConnectEntityHasTokenProvider(eventReference: eventReference),
            )
            .valueOrNull ??
        false;
    final isEditable = _isEntityEditable(entity);

    // If post already has first buy and is not editable anymore, no menu should be shown.
    if (hasFirstBuy && !isEditable) {
      return const SizedBox.shrink();
    }

    // Edit menu item for posts and articles
    if (entity is ModifiablePostEntity && isEditable) {
      editMenuItems.add(
        ListItem(
          onTap: () {
            Navigator.of(context).pop();

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
          leading: OutlinedIcon(
            icon: Assets.svg.iconEditLink.icon(
              size: 20.0.s,
              color: context.theme.appColors.primaryAccent,
            ),
          ),
          title: Text(
            context.i18n.button_edit,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
      );
    }

    // Edit menu item for articles
    if (entity is ArticleEntity && _isEntityEditable(entity)) {
      editMenuItems.add(
        ListItem(
          onTap: () {
            Navigator.of(context).pop();

            final modifiedEvent = entity.toEventReference().encode();
            EditArticleRoute(modifiedEvent: modifiedEvent).push<void>(context);
          },
          leading: OutlinedIcon(
            icon: Assets.svg.iconEditLink.icon(
              size: 20.0.s,
              color: context.theme.appColors.primaryAccent,
            ),
          ),
          title: Text(
            context.i18n.button_edit,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
      );
    }

    if (editMenuItems.isNotEmpty) {
      menuItemsGroups.add(editMenuItems);
    }

    // Add Delete menu item only if there was no first buy.
    if (!hasFirstBuy) {
      deleteMenuItems.add(
        ListItem(
          onTap: () async {
            Navigator.of(context).pop();
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
          leading: OutlinedIcon(
            icon: Assets.svg.iconBlockDelete.icon(
              size: 20.0.s,
              color: context.theme.appColors.attentionRed,
            ),
          ),
          title: Text(
            context.i18n.post_menu_delete,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.attentionRed,
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
      );

      menuItemsGroups.add(deleteMenuItems);
    }

    return BottomSheetMenuContent(
      groups: menuItemsGroups,
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
      final ArticleEntity _ => true,
      _ => false,
    };
  }
}
