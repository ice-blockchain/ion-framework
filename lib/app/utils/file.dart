// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:open_filex/open_filex.dart';

Future<MediaFile> saveBytesIntoFile({
  required List<int> bytes,
  required String extension,
  required String outputFilePath,
  required MimeType mimeType,
  String? originalMimeType,
  String? name,
}) async {
  final outputFile = File(outputFilePath);
  await outputFile.writeAsBytes(bytes);

  return MediaFile(
    path: outputFilePath,
    mimeType: mimeType.value,
    originalMimeType: originalMimeType,
    name: name,
    width: 0,
    height: 0,
  );
}

/// Opens a file with the system's default app for that file type
Future<bool> openFile(String filePath) async {
  final file = File(filePath);

  if (!file.existsSync()) {
    return false;
  }

  // If file has .bin extension (default when unable to determine file type),
  // return false to trigger share fallback instead of trying to open
  if (filePath.toLowerCase().endsWith('.bin')) {
    return false;
  }

  try {
    final result = await OpenFilex.open(filePath);
    return result.type == ResultType.done;
  } catch (e) {
    return false;
  }
}
