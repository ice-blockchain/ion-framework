// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/image_path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_service.m.freezed.dart';
part 'media_service.m.g.dart';

@freezed
class MediaFile with _$MediaFile {
  const factory MediaFile({
    required String path,
    int? size,
    String? name,
    int? width,
    int? height,
    String? mimeType,
    String? originalMimeType,
    String? thumb,
    String? blurhash,
    int? duration,
  }) = _MediaFile;

  const MediaFile._();

  factory MediaFile.fromJson(Map<String, dynamic> json) => _$MediaFileFromJson(json);

  String get basename => p.basename(path);
}

typedef CropImageUiSettings = List<PlatformUiSettings>;

class MediaService {
  final _streamController = StreamController<List<MediaFile>>.broadcast();
  int _currentPage = 0;
  MediaPickerType? _currentType;

  Future<void> presentLimitedGallery(RequestType type) async {
    return PhotoManager.presentLimited(type: type);
  }

  Future<void> fetchGalleryMediaPage({
    required int page,
    required int size,
    required MediaPickerType type,
  }) async {
    try {
      _currentPage = page;
      _currentType = type;

      final albums = await PhotoManager.getAssetPathList(
        type: type.toRequestType(),
      );

      if (albums.isEmpty) {
        if (page == 0) {
          _streamController.add([]);
        }
        return;
      }

      final assets = await albums.first.getAssetListPaged(
        page: page,
        size: size,
      );

      if (assets.isEmpty) {
        if (page == 0) {
          _streamController.add([]);
        }
        return;
      }

      const batchSize = 20;
      final totalBatches = (assets.length / batchSize).ceil();

      for (var i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = (start + batchSize < assets.length) ? start + batchSize : assets.length;
        final batch = assets.sublist(start, end);

        final batchResults = await _processBatch(batch);

        _streamController.add(batchResults);
      }
    } catch (e) {
      Logger.log('Error fetching gallery images: $e');
      if (page == 0) {
        _streamController.add([]);
      }
    }
  }

  static Future<List<MediaFile>> _processBatch(List<AssetEntity> batch) async {
    final mediaFiles = <MediaFile>[];

    for (final asset in batch) {
      String? mimeType;

      // For Android we can try to get the mimeType from the asset directly
      mimeType = (defaultTargetPlatform == TargetPlatform.android)
          ? asset.mimeType ?? await asset.mimeTypeAsync
          : await asset.mimeTypeAsync;

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

  Stream<List<MediaFile>> watchGalleryMedia({
    required int page,
    required int size,
    required MediaPickerType type,
  }) {
    // Handle changes from PhotoManager
    Future<void> onChangeCallback(MethodCall _) async {
      await fetchGalleryMediaPage(
        page: _currentPage,
        size: size,
        type: _currentType ?? type,
      );
    }

    PhotoManager.addChangeCallback(onChangeCallback);
    PhotoManager.startChangeNotify();

    _streamController.onCancel = () {
      PhotoManager.removeChangeCallback(onChangeCallback);
      PhotoManager.stopChangeNotify();
    };

    if (page == 0 || _currentType != type) {
      fetchGalleryMediaPage(
        page: page,
        size: size,
        type: type,
      );
    }

    return _streamController.stream;
  }

  Future<MediaFile?> cropImage({
    required String path,
    required CropImageUiSettings uiSettings,
    CropAspectRatio aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1),
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: aspectRatio,
      uiSettings: uiSettings,
    );

    if (croppedFile == null) return null;

    return MediaFile(path: croppedFile.path);
  }

  CropImageUiSettings buildCropImageUiSettings(
    BuildContext context, {
    CropStyle cropStyle = CropStyle.rectangle,
    List<CropAspectRatioPresetData> aspectRatioPresets = const [CropAspectRatioPreset.square],
  }) {
    return [
      AndroidUiSettings(
        toolbarTitle: context.i18n.common_crop_image,
        toolbarColor: context.theme.appColors.primaryAccent,
        toolbarWidgetColor: context.theme.appColors.primaryBackground,
        cropStyle: cropStyle,
        aspectRatioPresets: aspectRatioPresets,
        statusBarLight: false,
      ),
      IOSUiSettings(
        title: context.i18n.common_crop_image,
        cropStyle: cropStyle,
        aspectRatioPresets: aspectRatioPresets,
      ),
      // `WebUiSettings` is required for Web, `context` is also required
      WebUiSettings(context: context),
    ];
  }

  Future<MediaFile?> saveImageToGallery(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final asset = await PhotoManager.editor.saveImage(
      bytes,
      filename:
          'Camera_${DateTime.now().millisecondsSinceEpoch.toString() + p.extension(imageFile.path)}',
    );
    final file = await asset.file;

    if (file == null) return null;

    final mimeType = await asset.mimeTypeAsync;

    return MediaFile(
      path: asset.id,
      height: asset.height,
      width: asset.width,
      mimeType: mimeType,
    );
  }

  Future<MediaFile?> saveVideoToGallery(File videoFile) async {
    final bytes = await videoFile.readAsBytes();

    final tempDir = Directory.systemTemp;
    final tempPath =
        '${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch.toString() + p.extension(videoFile.path)}';
    final tempFile = await File(tempPath).writeAsBytes(bytes);

    final asset = await PhotoManager.editor.saveVideo(
      tempFile,
      title: 'Camera_${DateTime.now().millisecondsSinceEpoch}',
    );
    final file = await asset.file;
    if (file == null) return null;

    final mimeType = await asset.mimeTypeAsync;

    return MediaFile(
      path: asset.id,
      mimeType: mimeType,
    );
  }

  Future<({Uint8List imageBytes, Offset position, Size size})?> captureWidgetAsImage(
    RenderObject renderObject,
  ) async {
    try {
      if (renderObject is RenderRepaintBoundary) {
        final image = renderObject.toImageSync(pixelRatio: 3);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final imageBytes = byteData.buffer.asUint8List();
          final box = renderObject as RenderBox;
          final position = box.localToGlobal(Offset.zero);
          final size = box.size;
          return (imageBytes: imageBytes, position: position, size: size);
        }
      }
      return null;
    } catch (e, st) {
      Logger.log('Error capturing widget as image:', error: e, stackTrace: st);
      return null;
    }
  }

  // Convert all asset media id-s returned from MediaPicker to actual file path-es
  Future<List<MediaFile>> convertAssetIdsToMediaFiles(
    WidgetRef ref, {
    required List<MediaFile> mediaFiles,
  }) async {
    return Future.wait(
      mediaFiles.map((mediaFile) async {
        final assetEntity = await ref.read(assetEntityProvider(mediaFile.path).future);
        if (assetEntity == null) {
          throw AssetEntityFileNotFoundException();
        }

        final assetFileFuture = getAssetFile(assetEntity);

        final (mimeType, file) = await (assetEntity.mimeTypeAsync, assetFileFuture).wait;
        if (file == null) {
          throw AssetEntityFileNotFoundException();
        }
        return MediaFile(
          path: file.path,
          height: assetEntity.height,
          width: assetEntity.width,
          mimeType: mimeType,
          thumb: mediaFile.thumb,
          duration: assetEntity.duration,
        );
      }),
    );
  }

  Future<File?> getFileFromAppDirectory(String filename) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final file = File('${appDirectory.path}/$filename');
    if (!file.existsSync()) return null;

    return file;
  }

  Future<MediaFile?> convertKeyboardGifToMediaFile(KeyboardInsertedContent content) async {
    MediaFile? mediaFile;
    if (content.hasData && content.uri.isGif) {
      final outputPath = await generateOutputPath(extension: 'gif');
      final file = await File(outputPath).writeAsBytes(content.data!);
      mediaFile = MediaFile(path: file.path, mimeType: content.mimeType);
    } else {
      Logger.log(
        'Keyboard content is not a valid - mimeType ${content.mimeType} - uri: ${content.uri}',
      );
    }

    return mediaFile;
  }
}

@riverpod
MediaService mediaService(Ref ref) => MediaService();
