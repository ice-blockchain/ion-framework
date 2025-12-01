// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_filter_bar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_tokens_filter_provider.r.g.dart';

@riverpod
class CreatorTokensFilter extends _$CreatorTokensFilter {
  @override
  CreatorTokensFilterType build(CreatorTokensTabType tabType) {
    return CreatorTokensFilterType.allTokens;
  }

  set filter(CreatorTokensFilterType filter) {
    state = filter;
  }
}
