// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/gallery/providers/albums_provider.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/gallery/views/components/albums/album_item.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class AlbumSelectionPage extends ConsumerWidget {
  const AlbumSelectionPage({
    required this.type,
    required this.isNeedFilterVideoByFormat,
    this.isBottomSheet = false,
    super.key,
  });

  final MediaPickerType type;
  final bool isBottomSheet;
  final bool isNeedFilterVideoByFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(
      albumsProvider(
        type: type,
        isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
      ),
    );
    final currentAlbum = ref
        .watch(
          galleryNotifierProvider(
            type: type,
            isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
          ),
        )
        .valueOrNull
        ?.selectedAlbum;

    final content = CustomScrollView(
      slivers: [
        SliverAppBar(
          primary: false,
          flexibleSpace: NavigationAppBar.modal(
            title: Text(
              context.i18n.gallery_albums_select_title,
              style: context.theme.appTextThemes.subtitle,
            ),
            onBackPress: () => context.pop(),
          ),
          automaticallyImplyLeading: false,
          toolbarHeight: NavigationAppBar.modalHeaderHeight,
          pinned: true,
        ),
        SliverPadding(padding: EdgeInsetsDirectional.only(top: 12.0.s)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: albumsAsync.valueOrNull?.length ?? 0,
            (context, index) {
              final albums = albumsAsync.valueOrNull;
              if (albums == null) {
                return const SizedBox.shrink();
              }

              if (index >= albums.length) return null;

              final album = albums[index];
              final isSelected = (album.id == currentAlbum?.id);

              return AlbumItem(
                albumId: album.id,
                name: album.name,
                assetCount: album.assetCount,
                isAll: album.isAll,
                isSelected: isSelected,
                isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
                onTap: () {
                  ref
                      .read(
                        galleryNotifierProvider(
                          type: type,
                          isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
                        ).notifier,
                      )
                      .selectAlbum(
                        album,
                      );
                  context.pop();
                },
              );
            },
          ),
        ),
      ],
    );

    return isBottomSheet
        ? SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.9,
            child: content,
          )
        : SheetContent(
            body: content,
          );
  }
}
