// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/settings/optimistic_ui/model/who_can_message_privacy_option.f.dart';

/// Sync strategy for who can message visibility option using IonConnectNotifier.
class WhoCanMessageStrategy implements SyncStrategy<WhoCanMessagePrivacyOption> {
  WhoCanMessageStrategy({required this.updateVisibility});

  final Future<void> Function(UserVisibilityPrivacyOption) updateVisibility;

  @override
  Future<WhoCanMessagePrivacyOption> send(
    WhoCanMessagePrivacyOption previous,
    WhoCanMessagePrivacyOption optimistic,
  ) async {
    if (previous.visibility != optimistic.visibility) {
      await updateVisibility(optimistic.visibility);
    }

    return optimistic;
  }
}
