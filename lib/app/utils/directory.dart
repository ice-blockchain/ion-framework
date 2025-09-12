// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';

void ensureDirectoryExists(String filePath) {
  final dir = Directory(dirname(filePath));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}

Future<String> getSharedDatabasePath({
  required String databaseName,
  required String appGroupId,
}) async {
  try {
    final sharedPath =
        await PathProviderFoundation().getContainerPath(appGroupIdentifier: appGroupId);

    final basePath = (sharedPath?.isNotEmpty ?? false)
        ? sharedPath!
        : (await getApplicationDocumentsDirectory()).path;

    final dbFile = join(basePath, '$databaseName.sqlite');

    ensureDirectoryExists(dbFile);

    return dbFile;
  } catch (e) {
    final dbFile = join((await getApplicationDocumentsDirectory()).path, '$databaseName.sqlite');
    ensureDirectoryExists(dbFile);

    return dbFile;
  }
}
