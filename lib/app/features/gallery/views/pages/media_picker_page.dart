// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/gallery/data/models/gallery_state.f.dart';
import 'package:ion/app/features/gallery/providers/providers.dart';
import 'package:ion/app/features/gallery/views/components/components.dart';
import 'package:ion/app/features/gallery/views/components/manage_access_banner.dart';
import 'package:ion/app/features/gallery/views/pages/album_selection_page.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class MediaPickerPage extends HookConsumerWidget {
  const MediaPickerPage({
    required this.maxSelection,
    super.key,
    this.type = MediaPickerType.common,
    this.title,
    this.isBottomSheet = false,
    this.maxVideoDurationInSeconds,
    this.showCameraCell = true,
    this.onSelectCallback,
    this.preselectedMedia,
  });

  final int maxSelection;
  final MediaPickerType type;
  final String? title;
  final bool isBottomSheet;
  final int? maxVideoDurationInSeconds;
  final bool showCameraCell;
  final void Function(List<MediaFile> media)? onSelectCallback;
  final List<String>? preselectedMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryNotifierProvider(type: type));
    final selectedMedia = ref.watch(
      mediaSelectionNotifierProvider.select((state) => state.selectedMedia),
    );
    final hasLimitedPermission = ref.watch(hasLimitedPermissionProvider(Permission.photos));

    final isAll = galleryState.valueOrNull?.selectedAlbum?.isAll ?? false;
    final albumName = galleryState.valueOrNull?.selectedAlbum?.name ?? type.title(context);

    ref.listen(mediaSelectionNotifierProvider, (_, value) {
      if (maxSelection == 1 && value.selectedMedia.isNotEmpty == true) {
        // this is need to avoid this callback running too early, before the previous screen
        // is closed
        if (onSelectCallback == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop(value.selectedMedia);
            }
          });
        } else {
          onSelectCallback!(value.selectedMedia);
          ref.invalidate(mediaSelectionNotifierProvider);
        }
      }
    });

    useOnInit(
      () {
        ref.read(mediaSelectionNotifierProvider.notifier).updateMaxSelection(maxSelection);
        ref
            .read(mediaSelectionNotifierProvider.notifier)
            .updateDurationLimit(maxVideoDurationInSeconds);
      },
      [maxSelection, maxVideoDurationInSeconds],
    );

    useRoutePresence(
      onBecameInactive: () {
        ref.invalidate(mediaSelectionNotifierProvider);
      },
    );

    final slivers = [
      SliverAppBar(
        primary: false,
        flexibleSpace: NavigationAppBar.modal(
          title: Button.dropdown(
            onPressed: () {
              showSimpleBottomSheet<List<MediaFile>>(
                context: context,
                child: AlbumSelectionPage(
                  type: type,
                  isBottomSheet: true,
                ),
              );
            },
            label: Text(
              isAll ? context.i18n.core_all : albumName,
              style: context.theme.appTextThemes.subtitle,
            ),
            trailingIconOffset: 2.0.s,
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
          ),
          onBackPress: () => Navigator.of(context).pop(),
          actions: [
            if (maxSelection > 1 && selectedMedia.isNotEmpty)
              AddMediaButton(
                onPressed: () => Navigator.of(context).pop(selectedMedia),
                mediaCount: selectedMedia.length,
              ),
          ],
        ),
        automaticallyImplyLeading: false,
        pinned: true,
      ),
      if (hasLimitedPermission)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.only(bottom: 12.0.s),
            child: ManageAccessBanner(type: type),
          ),
        ),
      GalleryGridView(
        type: type,
        showSelectionBadge: maxSelection > 1,
        showCameraCell: showCameraCell,
        galleryState: galleryState.valueOrNull ??
            GalleryState(
              mediaData: [],
              currentPage: 0,
              hasMore: true,
              isLoading: false,
              type: type,
            ),
      ),
    ];

    final loadMoreBuilder = LoadMoreBuilder(
      slivers: slivers,
      hasMore: galleryState.value?.hasMore ?? false,
      onLoadMore: () => ref.read(galleryNotifierProvider(type: type).notifier).fetchNextPage(),
    );

    return isBottomSheet
        ? SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.9,
            child: loadMoreBuilder,
          )
        : SheetContent(
            body: loadMoreBuilder,
          );
  }
}
