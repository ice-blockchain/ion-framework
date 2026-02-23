// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/suggestions/cashtags/remote_cashtag_search_provider.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cashtag_suggestions_provider.r.g.dart';

@riverpod
Future<List<CoinData>> cashtagSuggestions(Ref ref, String query) async {
  if (query.isEmpty || !query.startsWith(r'$')) {
    return [];
  }

  final searchQuery = query.substring(1).toLowerCase();

  try {
    return await ref.read(remoteCashtagSearchProvider(searchQuery).future);
  } catch (e) {
    return [];
  }
}
