// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:ion/app/features/core/services/shared_core_isolate.dart';
import 'package:ion/app/utils/directory.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Creates a [QueryExecutor] that runs on a manually created isolate.
/// This provides better control over isolate management and uses the shared core isolate.
///
/// If [appGroupId] is provided, the database will be stored in the shared app group container.
/// Otherwise, it will be stored in the application documents directory.
///
/// [setupCallback] is an optional function that will be called when setting up the database.
/// It's typically used to execute initialization SQL like enabling WAL mode.
QueryExecutor createDatabaseExecutorWithManualIsolate({
  required String databaseName,
  String? appGroupId,
  DatabaseSetup? setupCallback,
}) {
  return DatabaseConnection.delayed(
    Future(() async {
      final dbPath = await _getDatabasePath(databaseName, appGroupId);
      final isolate = await _createIsolate(dbPath, setupCallback);
      return isolate.connect();
    }),
  );
}

/// Gets the database path based on whether an app group ID is provided
Future<String> _getDatabasePath(String databaseName, String? appGroupId) async {
  if (appGroupId == null) {
    return join(
      (await getApplicationDocumentsDirectory()).path,
      '$databaseName.sqlite',
    );
  }
  return getSharedDatabasePath(databaseName: databaseName, appGroupId: appGroupId);
}

/// Creates a Drift isolate manually using the shared core isolate
Future<DriftIsolate> _createIsolate(
  String dbPath,
  DatabaseSetup? setupCallback,
) async {
  final receiverPort = ReceivePort();

  try {
    await sharedCoreIsolate(
      (message) async {
        final server = DriftIsolate.inCurrent(() {
          return LazyDatabase(() async {
            return NativeDatabase(
              File(dbPath),
              setup: setupCallback,
            );
          });
        });
        message.send(server);
      },
      receiverPort.sendPort,
    );

    final server = await receiverPort.first;

    if (server is! DriftIsolate) {
      throw StateError('Expected DriftIsolate but got ${server.runtimeType}');
    }

    return server;
  } finally {
    receiverPort.close();
  }
}
