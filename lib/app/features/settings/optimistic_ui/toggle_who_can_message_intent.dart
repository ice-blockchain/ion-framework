// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/settings/optimistic_ui/model/who_can_message_privacy_option.f.dart';

/// Intent to toggle who can message a user.
final class ToggleWhoCanMessageIntent implements OptimisticIntent<WhoCanMessagePrivacyOption> {
  @override
  WhoCanMessagePrivacyOption optimistic(WhoCanMessagePrivacyOption current) => current.copyWith(
        visibility: current.visibility == UserVisibilityPrivacyOption.everyone
            ? UserVisibilityPrivacyOption.followedPeople
            : UserVisibilityPrivacyOption.everyone,
      );

  @override
  Future<WhoCanMessagePrivacyOption> sync(
    WhoCanMessagePrivacyOption prev,
    WhoCanMessagePrivacyOption next,
  ) =>
      throw UnimplementedError('Sync is handled by strategy');
}
