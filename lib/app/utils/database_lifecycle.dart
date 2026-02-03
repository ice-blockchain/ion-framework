// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/extensions/ref_lifecycle_listen_extension.dart';
import 'package:ion/app/services/logger/logger.dart';

/// Registers common lifecycle callbacks for a drift [database]:
/// - Closes the database on logout and user switch.
/// - Runs a WAL checkpoint when the app goes to background.
void registerDatabaseLifecycle(Ref ref, GeneratedDatabase database) {
  onLogout(ref, database.close);
  onUserSwitch(ref, database.close);
  ref.listenOnLifecycleTransition(
    to: AppLifecycleStatus.hidden,
    onTransition: (_, __) {
      try {
        unawaited(
          database
              .customStatement(DatabaseConstants.walCheckpointTruncate)
              .catchError((Object error, StackTrace stackTrace) {
            Logger.log('WAL checkpoint failed', error: error);
          }),
        );
      } catch (error) {
        Logger.log('WAL checkpoint failed', error: error);
      }
    },
  );
}
