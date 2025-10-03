// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/delete/delete_confirmation_type.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/providers/delete_entity_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/current_user_feed_story_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class EntityDeleteConfirmationModal extends HookConsumerWidget {
  const EntityDeleteConfirmationModal({
    required this.eventReference,
    required this.deleteConfirmationType,
    super.key,
  });

  final DeleteConfirmationType deleteConfirmationType;
  final EventReference eventReference;

  static double get buttonsSize => 56.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonMinimalSize = Size(buttonsSize, buttonsSize);

    final deleteState = ref.watch(deleteEntityControllerProvider);

    ref
      ..displayErrors(deleteEntityControllerProvider)
      ..listenSuccess(
        deleteEntityControllerProvider,
        (_) {
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
      );

    return ScreenSideOffset.small(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48.0.s),
          InfoCard(
            iconAsset: deleteConfirmationType.iconAsset,
            title: deleteConfirmationType.getTitle(context),
            description: deleteConfirmationType.getDesc(context),
          ),
          SizedBox(height: 28.0.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Button.compact(
                  type: ButtonType.outlined,
                  label: Text(context.i18n.button_cancel),
                  onPressed: () {
                    context.pop(false);
                  },
                  disabled: deleteState.isLoading,
                  minimumSize: buttonMinimalSize,
                ),
              ),
              SizedBox(width: 15.0.s),
              Expanded(
                child: Button.compact(
                  label: Text(context.i18n.button_delete),
                  trailingIcon: deleteState.isLoading ? const IONLoadingIndicator() : null,
                  onPressed: () async {
                    await ref.read(deleteEntityControllerProvider.notifier).deleteByReference(
                          eventReference,
                          onDelete: _getOnDeleteCallback(ref, eventReference),
                        );
                  },
                  disabled: deleteState.isLoading,
                  minimumSize: buttonMinimalSize,
                  backgroundColor: context.theme.appColors.attentionRed,
                ),
              ),
            ],
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }

  FutureOr<void> Function()? _getOnDeleteCallback(WidgetRef ref, EventReference eventReference) {
    return switch (deleteConfirmationType) {
      DeleteConfirmationType.story => () => _refreshProviders(ref, eventReference),
      _ => null,
    };
  }

  void _refreshProviders(WidgetRef ref, EventReference eventReference) {
    if (ref.context.mounted) return;
    final pubkey = ref.read(currentPubkeySelectorProvider) ?? '';
    final id = switch (eventReference) {
      ImmutableEventReference() => eventReference.eventId,
      ReplaceableEventReference() => eventReference.dTag,
      _ => throw ArgumentError(
          'Unsupported EventReference type: ${eventReference.runtimeType}',
        ),
    };
    ref.read(feedStoriesProvider.notifier).refresh();
    ref.read(currentUserFeedStoryProvider.notifier).refresh();
    ref.read(userStoriesProvider(pubkey).notifier).removeStory(id);
    ref.read(ionConnectCacheProvider.notifier).remove(
          EventCountResultEntity.cacheKeyBuilder(
            key: pubkey,
            type: EventCountResultType.stories,
          ),
        );
  }
}
