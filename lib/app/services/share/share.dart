// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';

void shareContent(String text, {String? subject}) {
  Share.share(text, subject: subject);
}

Future<void> shareFile(String path, {String name = ''}) {
  final bytes = File(path).readAsBytesSync();

  return Share.shareXFiles(
    [
      XFile.fromData(
        bytes,
        mimeType: lookupMimeType(path, headerBytes: bytes),
        name: name,
      ),
    ],
    subject: name,
    fileNameOverrides: [
      name,
    ],
  );
}
