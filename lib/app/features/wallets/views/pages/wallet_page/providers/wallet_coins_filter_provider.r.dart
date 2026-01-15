// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/pages/creator_tokens/models/token_type_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_coins_filter_provider.r.g.dart';

@riverpod
class WalletCoinsFilterNotifier extends _$WalletCoinsFilterNotifier {
  @override
  TokenTypeFilter build() => TokenTypeFilter.all;

  set filter(TokenTypeFilter value) {
    state = value;
  }
}
