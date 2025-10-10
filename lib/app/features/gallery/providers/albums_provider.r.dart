// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/gallery/data/models/album_data.f.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/services/media_service/album_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'albums_provider.r.g.dart';

@Riverpod(keepAlive: true)
AlbumService albumService(Ref ref) => AlbumService();

@riverpod
Future<List<AlbumData>> albums(
  Ref ref, {
  required MediaPickerType type,
  bool isNeedFilterVideoByFormat = false,
}) {
  final albumService = ref.watch(albumServiceProvider);
  return albumService.fetchAlbums(
    type: type,
    isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
  );
}

@riverpod
Future<AssetEntity?> albumPreview(
  Ref ref,
  String albumId, {
  bool isNeedFilterVideoByFormat = false,
}) async {
  final albumService = ref.watch(albumServiceProvider);
  return albumService.fetchFirstAssetOfAlbum(
    albumId,
    isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
  );
}
