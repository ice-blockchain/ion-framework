// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/gallery/data/models/models.dart';
import 'package:ion/app/features/gallery/providers/albums_provider.r.dart';
import 'package:ion/app/features/gallery/providers/providers.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_provider.r.g.dart';

@riverpod
Future<AssetEntity?> assetEntity(Ref ref, String id) {
  return AssetEntity.fromId(id);
}

@riverpod
Future<AssetEntity?> latestGalleryPreview(Ref ref) async {
  final mediaService = ref.watch(mediaServiceProvider);
  final mediaData = await mediaService
      .watchGalleryMedia(
        page: 0,
        size: 1,
        type: MediaPickerType.image,
      )
      .first;

  return await ref.watch(assetEntityProvider(mediaData.first.path).future);
}

@riverpod
Future<String?> assetFilePath(Ref ref, String assetId) async {
  final assetEntity = await ref.watch(assetEntityProvider(assetId).future);

  if (assetEntity == null) return null;

  final file = await assetEntity.file;

  return file?.path;
}

@riverpod
class GalleryNotifier extends _$GalleryNotifier {
  static const int _pageSize = 100;

  @override
  Future<GalleryState> build({MediaPickerType type = MediaPickerType.common}) async {
    final mediaService = ref.watch(mediaServiceProvider);
    final hasPermission = ref.watch(hasPermissionProvider(Permission.photos));

    if (!hasPermission) {
      Logger.log('Photos Permission denied');
      return GalleryState(
        mediaData: [],
        currentPage: 0,
        hasMore: false,
        type: type,
        isLoading: false,
      );
    }

    final mediaSubscription = mediaService
        .watchGalleryMedia(
      page: 0,
      size: _pageSize,
      type: type,
    )
        .listen((media) {
      final currentState = state.valueOrNull;
      final existingMedia = currentState?.mediaData ?? [];
      final existingMediaPaths = existingMedia.map((m) => m.path).toSet();
      final newMedia = media.where((m) => !existingMediaPaths.contains(m.path)).toList();

      state = AsyncValue.data(
        GalleryState(
          mediaData: [...existingMedia, ...newMedia],
          currentPage: currentState?.currentPage ?? 0,
          hasMore: media.isNotEmpty,
          type: type,
          isLoading: false,
        ),
      );
    });

    ref.onDispose(mediaSubscription.cancel);

    return GalleryState(
      mediaData: [],
      currentPage: 1,
      hasMore: false,
      type: type,
      isLoading: false,
    );
  }

  Future<void> fetchNextPage() async {
    final currentState = state.valueOrNull;

    if (currentState == null || currentState.isLoading) return;
    if (!currentState.hasMore) return;

    if (currentState.selectedAlbum == null) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoading: true,
          currentPage: currentState.currentPage + 1,
        ),
      );

      await ref.read(mediaServiceProvider).fetchGalleryMediaPage(
            page: currentState.currentPage,
            size: _pageSize,
            type: currentState.type,
          );

      return;
    }

    state = await AsyncValue.guard(() async {
      final newMedia = await _fetchMediaFromSelectedAlbum(
        album: currentState.selectedAlbum!,
        page: currentState.currentPage,
        size: _pageSize,
        type: currentState.type,
      );

      final hasMore = newMedia.length == _pageSize;

      return currentState.copyWith(
        mediaData: [...currentState.mediaData, ...newMedia],
        currentPage: currentState.currentPage + 1,
        hasMore: hasMore,
        isLoading: false,
      );
    });
  }

  Future<void> selectAlbum(AlbumData album) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newState = await _loadCurrentAlbum(
        oldState: currentState.copyWith(selectedAlbum: album, mediaData: []),
        page: 0,
        type: currentState.type,
      );
      return newState;
    });
  }

  Future<GalleryState> _loadCurrentAlbum({
    required GalleryState oldState,
    required int page,
    required MediaPickerType type,
  }) async {
    var album = oldState.selectedAlbum;
    if (album == null) {
      final albumList = await ref.read(albumsProvider(type: type).future);
      if (albumList.isEmpty) {
        return oldState.copyWith(
          mediaData: [],
          currentPage: 0,
          hasMore: false,
          selectedAlbum: null,
        );
      }

      album = albumList.firstWhereOrNull((a) => a.isAll) ?? albumList.first;
    }

    final newMedia = await _fetchMediaFromSelectedAlbum(
      album: album,
      page: page,
      size: _pageSize,
      type: type,
    );

    return oldState.copyWith(
      mediaData: newMedia,
      currentPage: page + 1,
      hasMore: newMedia.length == _pageSize,
      selectedAlbum: album,
    );
  }

  Future<List<MediaFile>> _fetchMediaFromSelectedAlbum({
    required AlbumData album,
    required int page,
    required int size,
    required MediaPickerType type,
  }) async {
    final albumService = ref.read(albumServiceProvider);
    final mediaFiles = await albumService.fetchMediaFromAlbum(
      albumId: album.id,
      page: page,
      size: size,
    );

    return mediaFiles;
  }

  Future<void> addCapturedMediaFileToGallery(MediaFile mediaFile) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = await AsyncValue.guard(() async {
      final updated = [mediaFile, ...currentState.mediaData];
      return currentState.copyWith(mediaData: updated);
    });

    final updatedState = state.valueOrNull;
    if (updatedState != null) {
      ref
          .read(mediaSelectionNotifierProvider.notifier)
          .toggleSelection(mediaFile.path, type: updatedState.type);
    }
  }
}
