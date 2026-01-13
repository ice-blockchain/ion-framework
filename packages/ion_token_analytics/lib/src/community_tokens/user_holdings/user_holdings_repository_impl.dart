// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/user_holdings/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/user_holdings/user_holdings_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class UserHoldingsRepositoryImpl implements UserHoldingsRepository {
  UserHoldingsRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<UserHoldingsData> getUserHoldings({
    required String holder,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/v1/community-tokens/',
      queryParameters: {'holder': holder, 'limit': limit, 'offset': offset},
    );

    final items = response.map((e) => CommunityToken.fromJson(e as Map<String, dynamic>)).toList();

    final hasMore = items.length == limit;
    final nextOffset = offset + items.length;

    // TODO: Extract X_Total_Holdings from response headers when available
    final totalHoldings = items.length + (hasMore ? 1 : 0);

    return UserHoldingsData(
      items: items,
      totalHoldings: totalHoldings,
      nextOffset: nextOffset,
      hasMore: hasMore,
    );
  }
}
