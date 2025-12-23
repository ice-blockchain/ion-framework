// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/utils/url.dart';
import 'package:photo_manager/photo_manager.dart';

extension ImagePathExtension on String {
  bool get isSvg =>
      toLowerCase().endsWith('.svg') ||
      // for URLs coming from BE like https://api.dicebear.com/7.x/avataaars/svg?seed=diwataleaba77b590
      toLowerCase().contains('/svg?');

  bool get isGif => toLowerCase().endsWith('.gif');

  bool get isNetworkSvg => isNetworkUrl(toLowerCase()) && isSvg;
}

Future<File?> getAssetFile(AssetEntity assetEntity) async {
  final isAnimated = await _isAnimatedAsset(assetEntity);

  File? resultFile;
  if (isAnimated) {
    resultFile = await assetEntity.originFile;
  } else {
    resultFile = await assetEntity.file;
  }

  return resultFile;
}

Future<bool> _isAnimatedAsset(AssetEntity assetEntity) async {
  final isGif = await _isGifAsset(assetEntity);
  if (isGif) {
    return true;
  }

  if (assetEntity.mimeType == MimeType.image.value) {
    return true;
  }

  final file = await assetEntity.originFile;
  final path = file?.path;

  if (path != null && path.toLowerCase().endsWith('.webp')) {
    return true;
  }

  return false;
}

Future<bool> _isGifAsset(AssetEntity assetEntity) async {
  if (assetEntity.mimeType == LocalMimeType.gif.value) {
    return true;
  }

  final file = await assetEntity.originFile;
  final path = file?.path;
  if (path != null && path.isGif) {
    return true;
  }

  return false;
}
