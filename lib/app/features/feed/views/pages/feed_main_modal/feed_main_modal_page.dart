// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_sheets.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
import 'package:ion/app/features/feed/constants/video_constants.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/nft/sync/nft_collection_sync_controller.r.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_page.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/main_modal_item.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/model/main_modal_list_item.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/media_service/banuba_service.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedMainModalPage extends ConsumerWidget {
  const FeedMainModalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNftCollectionState = ref.watch(hasIonContentNftCollectionProvider);

    return SheetContent(
      backgroundColor: context.theme.appColors.secondaryBackground,
      topPadding: 0.0.s,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: hasNftCollectionState.when(
          data: (hasContentNftCollection) => hasContentNftCollection
              ? const _CreateContentModal()
              : const _ContentCreationBlockedModal(),
          loading: () => const _CreateContentLoadingModal(),
          error: (error, __) => ErrorModal(error: error),
        ),
      ),
    );
  }
}

class _CreateContentModal extends StatelessWidget {
  const _CreateContentModal();

  static const List<FeedType> feedTypeValues = FeedType.values;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          title: Text(context.i18n.feed_modal_title),
          showBackButton: false,
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const HorizontalSeparator(),
          itemCount: feedTypeValues.length,
          itemBuilder: (BuildContext context, int index) {
            final type = feedTypeValues[index];
            switch (type) {
              case FeedType.post:
                return _SharePostButton(type: type, index: index);
              case FeedType.story:
                return _ShareStoryButton(type: type, index: index);
              case FeedType.video:
                return _ShareVideoButton(type: type, index: index);
              case FeedType.article:
                return _ShareArticleButton(type: type, index: index);
            }
          },
        ),
      ],
    );
  }
}

class _ContentCreationBlockedModal extends HookConsumerWidget {
  const _ContentCreationBlockedModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;
    final locale = context.i18n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScreenSideOffset.medium(
          child: Column(
            children: [
              SizedBox(height: 24.s),
              Assets.svg.walleticonwalletemptypost.icon(size: 80.s),
              SizedBox(height: 10.s),
              Text(
                locale.feed_content_creation_blocked_title,
                style: textStyles.title,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.s),
              Text(
                locale.feed_content_creation_blocked_description,
                style: textStyles.body2.copyWith(color: colors.secondaryText),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.s),
              Button(
                minimumSize: Size(double.infinity, 56.s),
                label: Text(locale.button_try_again),
                leadingIcon: Assets.svg.iconbuttonTryagain.icon(size: 24.s),
                onPressed: () {
                  invalidateCurrentUserMetadataProviders(ref);
                },
              ),
            ],
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }
}

class _CreateContentLoadingModal extends StatelessWidget {
  const _CreateContentLoadingModal();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 291.s),
      child: const Center(
        child: IONLoadingIndicatorThemed(),
      ),
    );
  }
}

class _SharePostButton extends HookConsumerWidget {
  const _SharePostButton({
    required this.type,
    required this.index,
  });

  final MainModalListItem type;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainModalItem(
      item: type,
      onTap: () async {
        await CreatePostRoute().push<void>(context);
        if (context.mounted && context.canPop()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.pop();
            }
          });
        }
      },
      index: index,
    );
  }
}

class _ShareStoryButton extends HookConsumerWidget {
  const _ShareStoryButton({required this.type, required this.index});
  final MainModalListItem type;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionAwareWidget(
      permissionType: Permission.camera,
      requestId: 'story_record',
      builder: (_, onPressed) => MainModalItem(
        item: type,
        onTap: onPressed,
        index: index,
      ),
      onGranted: () async {
        await StoryRecordRoute().push<void>(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pop();
          }
        });
      },
      requestDialog: const PermissionRequestSheet(
        permission: Permission.camera,
      ),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.camera),
    );
  }
}

class _ShareVideoButton extends HookConsumerWidget {
  const _ShareVideoButton({required this.type, required this.index});
  final MainModalListItem type;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionAwareWidget(
      permissionType: Permission.photos,
      onGranted: () async {
        Future<void> showMediaPickerAndCreatePost() async {
          await showSimpleBottomSheet<List<MediaFile>>(
            context: context,
            child: MediaPickerPage(
              maxSelection: 1,
              isBottomSheet: true,
              type: MediaPickerType.video,
              onSelectCallback: (result) async {
                if (context.mounted) {
                  if (result.isNotEmpty) {
                    final editedMedia = await ref.read(
                      editMediaProvider(
                        result[0],
                        maxVideoDuration: VideoConstants.feedVideoMaxDuration,
                      ).future,
                    );
                    if (!context.mounted) return;
                    if (editedMedia == null) {
                      return;
                    } else {
                      final finishEditing = await CreateVideoRoute(
                        videoPath: editedMedia.path,
                        videoThumbPath: editedMedia.thumb,
                        mimeType: result[0].mimeType ?? '',
                      ).push<bool?>(context);

                      if (finishEditing.falseOrValue) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            context.pop();
                          }
                        });
                      }
                    }
                  } else {
                    context.pop();
                  }
                }
              },
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.pop();
            }
          });
        }

        await showMediaPickerAndCreatePost();
      },
      requestDialog: const PermissionRequestSheet(permission: Permission.photos),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.photos),
      builder: (_, onPressed) => MainModalItem(
        item: type,
        onTap: onPressed,
        index: index,
      ),
    );
  }
}

class _ShareArticleButton extends HookConsumerWidget {
  const _ShareArticleButton({required this.type, required this.index});
  final MainModalListItem type;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainModalItem(
      item: type,
      onTap: () async {
        await CreateArticleRoute().push<void>(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pop();
          }
        });
      },
      index: index,
    );
  }
}
