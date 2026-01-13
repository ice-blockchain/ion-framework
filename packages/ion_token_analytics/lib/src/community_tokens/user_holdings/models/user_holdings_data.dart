// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';

class UserHoldingsData {
  const UserHoldingsData({
    required this.items,
    required this.totalHoldings,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<CommunityToken> items;
  final int totalHoldings;
  final int nextOffset;
  final bool hasMore;
}
