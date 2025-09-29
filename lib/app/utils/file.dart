import 'dart:io';

import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

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
