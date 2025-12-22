// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/pages/creator_tokens/models/token_type_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_tokens_filter_provider.r.g.dart';

@riverpod
class CreatorTokensFilterNotifier extends _$CreatorTokensFilterNotifier {
  @override
  TokenTypeFilter build() => TokenTypeFilter.all;

  set filter(TokenTypeFilter value) {
    state = value;
  }
}
