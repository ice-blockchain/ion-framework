// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';

/// Intent to toggle block state for a user.
final class ToggleBlockIntent implements OptimisticIntent<BlockedUser> {
  @override
  BlockedUser optimistic(BlockedUser current) =>
      current.copyWith(isBlocked: !current.isBlocked);

  @override
  Future<BlockedUser> sync(BlockedUser prev, BlockedUser next) =>
      throw UnimplementedError('Sync is handled by strategy');
}
