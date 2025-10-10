// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/gallery/data/models/album_data.f.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/filter_video_by_format.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumService {
  final Map<String, AssetPathEntity> _albumsCache = {};

  AssetPathEntity? getAssetPathEntityById(String albumId) => _albumsCache[albumId];

  Future<AssetEntity?> fetchFirstAssetOfAlbum(
    String albumId, {
    required bool isNeedFilterVideoByFormat,
  }) async {
    final pathEntity = _albumsCache[albumId];
    if (pathEntity == null) return null;

    final assets = await pathEntity.getAssetListRange(start: 0, end: 10);
    final filteredAssets = filterUnsupportedVideoFormats(
      assets,
      isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
      filterVideoMimeTypeExtractor: (asset) => asset.mimeType,
    );
    if (filteredAssets.isEmpty) return null;

    return filteredAssets.first;
  }

  Future<List<AlbumData>> fetchAlbums({
    required MediaPickerType type,
    required bool isNeedFilterVideoByFormat,
  }) async {
    final assetPathList = await PhotoManager.getAssetPathList(
      type: type.toRequestType(),
    );

    _albumsCache.clear();

    final futures = assetPathList.map((ap) async {
      _albumsCache[ap.id] = ap;
      final count = await _countAssets(
        ap,
        isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
      );
      return AlbumData(
        id: ap.id,
        name: ap.name,
        assetCount: count,
        isAll: ap.isAll,
      );
    }).toList();

    return Future.wait(futures);
  }

  Future<List<MediaFile>> fetchMediaFromAlbum({
    required String albumId,
    required int page,
    required int size,
  }) async {
    final assetPath = _albumsCache[albumId];
    if (assetPath == null) {
      Logger.log('Album not found in cache: $albumId');
      return [];
    }

    final assets = await assetPath.getAssetListPaged(
      page: page,
      size: size,
    );

    final mediaFiles = <MediaFile>[];

    for (final asset in assets) {
      final mimeType = await asset.mimeTypeAsync;
      mediaFiles.add(
        MediaFile(
          path: asset.id,
          height: asset.height,
          width: asset.width,
          mimeType: mimeType,
        ),
      );
    }

    return mediaFiles;
  }

  Future<int> _countAssets(
    AssetPathEntity ap, {
    required bool isNeedFilterVideoByFormat,
  }) async {
    final allCount = await ap.assetCountAsync;
    if (!isNeedFilterVideoByFormat) {
      return allCount;
    }

    final allAssets = await ap.getAssetListRange(start: 0, end: allCount);
    final filteredAssets = filterUnsupportedVideoFormats(
      allAssets,
      isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
      filterVideoMimeTypeExtractor: (asset) => asset.mimeType,
    );
    return filteredAssets.length;
  }
}
