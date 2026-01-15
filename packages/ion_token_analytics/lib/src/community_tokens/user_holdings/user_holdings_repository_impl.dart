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
    final response = await _client.getWithResponse<List<dynamic>>(
      '/v1/community-tokens/',
      queryParameters: {'holder': holder, 'limit': limit, 'offset': offset},
    );

    final items = response.data
        .map((e) => CommunityToken.fromJson(e as Map<String, dynamic>))
        .toList();

    final hasMore = items.length == limit;
    final nextOffset = offset + items.length;

    final totalHoldings = _extractTotalHoldings(response.headers, items.length);

    return UserHoldingsData(
      items: items,
      totalHoldings: totalHoldings,
      nextOffset: nextOffset,
      hasMore: hasMore,
    );
  }

  /// Extracts the total holdings count from response headers.
  ///
  /// Looks for the X_Total_Holdings header.
  /// Falls back to [fallbackValue] if the header is missing or invalid.
  int _extractTotalHoldings(Map<String, String>? headers, int fallbackValue) {
    if (headers == null) {
      return fallbackValue;
    }

    final headerKey = headers.keys.firstWhere(
      (key) => key.toLowerCase() == 'x_total_holdings',
      orElse: () => '',
    );

    if (headerKey.isEmpty) {
      return fallbackValue;
    }

    final headerValue = headers[headerKey];
    if (headerValue == null) {
      return fallbackValue;
    }

    final parsed = int.tryParse(headerValue);
    return parsed ?? fallbackValue;
  }
}
