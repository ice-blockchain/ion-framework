// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/user_holdings/models/models.dart';

abstract class UserHoldingsRepository {
  /// Fetches tokens that the specified holder has a position in.
  ///
  /// [holder] is the ionConnect address or twitter address of the user.
  /// Returns tokens ordered by position amount (descending).
  Future<UserHoldingsData> getUserHoldings({
    required String holder,
    int limit = 20,
    int offset = 0,
  });
}
