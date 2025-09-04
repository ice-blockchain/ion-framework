// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

/// Pure-Dart WebP -> JPEG converter for use in background isolates (e.g., FCM).
Future<MediaFile> webpToJpeg(String inputPath) async {
  final inputFile = File(inputPath);
  final bytes = await inputFile.readAsBytes();

  // Early return if already JPEG (by extension)
  final lower = inputPath.toLowerCase();
  final isJpegByExt = lower.endsWith('.jpg') || lower.endsWith('.jpeg');
  if (isJpegByExt) {
    return MediaFile(
      path: inputPath,
      mimeType: LocalMimeType.jpeg.value,
      originalMimeType: LocalMimeType.jpeg.value,
    );
  }

  final decoded = img.decodeWebP(bytes);
  if (decoded == null) {
    throw StateError('Failed to decode WebP: $inputPath');
  }

  final jpgBytes = img.encodeJpg(decoded);
  final outPath = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '.jpg');
  final outFile = File(outPath);
  await outFile.writeAsBytes(jpgBytes, flush: true);

  return MediaFile(
    path: outPath,
    mimeType: LocalMimeType.jpeg.value,
    originalMimeType: MimeType.image.value,
    width: decoded.width,
    height: decoded.height,
  );
}
