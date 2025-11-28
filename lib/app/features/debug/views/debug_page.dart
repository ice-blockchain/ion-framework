// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:drift/drift.dart' as db;
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/core/providers/app_info_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/following_feed_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/user_block/providers/blocked_users_database_provider.r.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider).valueOrNull;
    final featureFlags = ref.watch(featureFlagsProvider);
    final talker = Logger.talker;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          title: const Text('🐞 Debug'),
          showBackButton: false,
          actions: const [NavigationCloseButton()],
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (appInfo != null)
                    ListTile(
                      title: Text(
                        '${appInfo.appName} v${appInfo.version} build ${appInfo.buildNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  if (talker != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('View Debug Logs'),
                        subtitle: const Text('Check application logs and diagnostics'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<TalkerScreen>(
                            builder: (context) => TalkerScreen(
                              talker: talker,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('View Drift Databases'),
                      subtitle: const Text('Explore database tables'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDatabaseSelectionDialog(context, ref),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Export & Share Databases'),
                      subtitle: const Text('Export database files and share them'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showExportDatabaseDialog(context, ref),
                    ),
                  ),
                  SizedBox(height: 16.0.s),
                  ExpansionTile(
                    title: const Text('Feature Flags'),
                    children: featureFlags.entries
                        .map(
                          (entry) => GestureDetector(
                            onTap: () => ref.read(featureFlagsProvider.notifier).toggle(entry.key),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(entry.key.key),
                                trailing: Icon(
                                  entry.value ? Icons.check_circle : Icons.cancel,
                                  color: entry.value ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDatabaseSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Database'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _DebugPageDatabaseType.values
                .map(
                  (dbType) => ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: Text(dbType.displayName),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openDatabaseViewer(context, ref, dbType);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showExportDatabaseDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export & Share Database'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _DebugPageDatabaseType.values
                .map(
                  (dbType) => ListTile(
                    leading: const Icon(Icons.share),
                    title: Text(dbType.displayName),
                    onTap: () {
                      Navigator.of(context).pop();
                      _exportAndShareDatabase(context, ref, dbType);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _openDatabaseViewer(BuildContext context, WidgetRef ref, _DebugPageDatabaseType dbType) {
    final database = _getDatabaseInstance(ref, dbType);
    Navigator.of(context).push(
      MaterialPageRoute<DriftDbViewer>(
        builder: (BuildContext context) {
          return DriftDbViewer(database);
        },
      ),
    );
  }

  Future<void> _exportAndShareDatabase(
    BuildContext context,
    WidgetRef ref,
    _DebugPageDatabaseType dbType,
  ) async {
    File? tempFile;
    try {
      _showProgressDialog(context, 'Exporting ${dbType.displayName}...');

      final database = _getDatabaseInstance(ref, dbType);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${dbType.name}_db_backup_$timestamp.db';
      tempFile = File('${directory.path}/$fileName');

      await tempFile.parent.create(recursive: true);

      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }

      await database.customStatement('VACUUM INTO ?', [tempFile.path]);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      await shareFile(tempFile.path, name: fileName);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showResultDialog(
          context,
          'Export Failed',
          'Error exporting database: $e',
        );
      }
    } finally {
      if (tempFile != null && tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    }
  }

  AlertDialog _showProgressDialog(BuildContext context, String message) {
    final dialog = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(message),
        ],
      ),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => dialog,
    );

    return dialog;
  }

  void _showResultDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  db.GeneratedDatabase _getDatabaseInstance(WidgetRef ref, _DebugPageDatabaseType dbType) {
    return switch (dbType) {
      _DebugPageDatabaseType.wallets => ref.read(walletsDatabaseProvider),
      _DebugPageDatabaseType.chat => ref.read(chatDatabaseProvider),
      _DebugPageDatabaseType.notifications => ref.read(notificationsDatabaseProvider),
      _DebugPageDatabaseType.blockedUsers => ref.read(blockedUsersDatabaseProvider),
      _DebugPageDatabaseType.followingFeed => ref.read(followingFeedDatabaseProvider),
    };
  }
}

enum _DebugPageDatabaseType {
  wallets('Wallets Database'),
  chat('Chat Database'),
  notifications('Notifications Database'),
  blockedUsers('Blocked Users Database'),
  followingFeed('Following Feed Database');

  const _DebugPageDatabaseType(this.displayName);
  final String displayName;
}
