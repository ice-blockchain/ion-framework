// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/gallery/providers/media_selection_provider.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_proccessor_notifier.m.freezed.dart';
part 'image_proccessor_notifier.m.g.dart';

@freezed
sealed class ImageProcessorState with _$ImageProcessorState {
  const factory ImageProcessorState.initial() = ImageProcessorStateInitial;
  const factory ImageProcessorState.picked({required MediaFile file}) = ImageProcessorStatePicked;
  const factory ImageProcessorState.cropped({required MediaFile file}) = ImageProcessorStateCropped;
  const factory ImageProcessorState.processed({required MediaFile file}) =
      ImageProcessorStateProcessed;
  const factory ImageProcessorState.error({required String message}) = ImageProcessorStateError;
}

@riverpod
class ImageProcessorNotifier extends _$ImageProcessorNotifier {
  @override
  ImageProcessorState build(ImageProcessingType type) => const ImageProcessorState.initial();

  Future<void> process({
    required String assetId,
    required CropImageUiSettings cropUiSettings,
  }) async {
    final mediaService = ref.read(mediaServiceProvider);
    final config = type.config;

    try {
      state = const ImageProcessorState.initial();

      final assetEntity = await ref.read(assetEntityProvider(assetId).future);
      if (assetEntity == null) {
        throw AssetEntityFileNotFoundException();
      }

      final file = await assetEntity.file;
      if (file == null) {
        throw AssetEntityFileNotFoundException();
      }

      final pickedFile = MediaFile(
        path: file.path,
        width: assetEntity.width,
        height: assetEntity.height,
      );
      state = ImageProcessorState.picked(file: pickedFile);

      Logger.info(
        'Original image dimensions: width=${assetEntity.width}, height=${assetEntity.height}',
      );

      final croppedImage = await mediaService.cropImage(
        uiSettings: cropUiSettings,
        path: file.path,
        aspectRatio: config.aspectRatio,
      );
      if (croppedImage == null) {
        state = const ImageProcessorState.initial();
        // Reset media selection when user cancels cropping
        ref.invalidate(mediaSelectionNotifierProvider);
        return;
      }

      state = ImageProcessorState.cropped(file: croppedImage);

      final compressedImage = await ref.read(imageCompressorProvider).compress(
            croppedImage,
            settings: ImageCompressionSettings(
              quality: config.quality,
            ),
          );
      state = ImageProcessorState.processed(file: compressedImage);

      Logger.info(
        'Compressed image dimensions: '
        'width=${compressedImage.width}, '
        'height=${compressedImage.height}, '
        'quality=${config.quality}',
      );
    } catch (error) {
      state = ImageProcessorState.error(message: error.toString());
    }
  }
}
