// SPDX-License-Identifier: ice License 1.0

class DatabaseConstants {
  DatabaseConstants._();

  static const String journalModeWAL = 'PRAGMA journal_mode = WAL';
  static const String walCheckpointTruncate = 'PRAGMA wal_checkpoint(TRUNCATE)';
}
