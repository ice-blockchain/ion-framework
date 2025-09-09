// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:path/path.dart';

void ensureDirectoryExists(String filePath) {
  final dir = Directory(dirname(filePath));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}
