// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';

class TradeCommunityLastPaymentCoinService {
  TradeCommunityLastPaymentCoinService({
    required this.userPreferencesService,
  });

  final UserPreferencesService userPreferencesService;

  static const _lastPaymentCoinKey = 'TokenizedCommunities:lastPaymentCoinSymbolGroup';

  /// Restores last used payment token from user preferences.
  /// Returns the matched CoinData if found in [supportedTokens], null otherwise.
  CoinData? restoreLastUsedPaymentToken(List<CoinData> supportedTokens) {
    if (supportedTokens.isEmpty) return null;

    final storedSymbolGroup = userPreferencesService.getValue<String>(_lastPaymentCoinKey);
    if (storedSymbolGroup == null || storedSymbolGroup.isEmpty) return null;

    final matched = supportedTokens.firstWhereOrNull(
      (t) => t.symbolGroup == storedSymbolGroup,
    );
    if (matched == null) return null;

    Logger.info(
      '[TC last payment coin] restored: ${matched.symbolGroup} (${matched.abbreviation})',
    );
    return matched;
  }

  /// Persists the selected payment token to user preferences.
  void saveLastUsedPaymentToken(CoinData token) {
    final symbolGroup = token.symbolGroup;
    userPreferencesService.setValue<String>(_lastPaymentCoinKey, symbolGroup);
    Logger.info(
      '[TC last payment coin] saved: $symbolGroup (${token.abbreviation})',
    );
  }
}
