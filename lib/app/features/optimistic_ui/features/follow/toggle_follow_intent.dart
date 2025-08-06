// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/model/user_follow.f.dart';

/// Intent to toggle follow state for a user.
final class ToggleFollowIntent implements OptimisticIntent<UserFollow> {
  @override
  UserFollow optimistic(UserFollow current) => current.copyWith(
        following: !current.following,
      );

  @override
  Future<UserFollow> sync(UserFollow prev, UserFollow next) =>
      throw UnimplementedError('Sync is handled by strategy');
}
