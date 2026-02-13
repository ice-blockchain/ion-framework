// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';

/// Registers common lifecycle callbacks for a drift [database]:
/// - Closes the database on logout and user switch.
/// - Runs a WAL checkpoint when the app goes to background.
void registerDatabaseLifecycle(Ref ref, GeneratedDatabase database) {
  onLogout(ref, database.close);
  // TODO(ice-damocles): Re-enable this once we have user switching is merged to RC
  //onUserSwitch(ref, database.close);
  onAppWentToBackground(
    ref,
    () => database.customStatement(DatabaseConstants.walCheckpointTruncate),
  );
}
