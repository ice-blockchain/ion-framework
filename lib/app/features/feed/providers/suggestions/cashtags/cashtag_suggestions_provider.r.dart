// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/domain/coins/search_coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cashtag_suggestions_provider.r.g.dart';

@riverpod
Future<List<CoinsGroup>> cashtagSuggestions(Ref ref, String query) async {
  if (query.isEmpty || !query.startsWith(r'$')) {
    return [];
  }

  final searchQuery = query.substring(1).toLowerCase();
  final searchService = ref.read(searchCoinsServiceProvider);

  try {
    final coinsGroups = await searchService.search(searchQuery);
    return coinsGroups.take(10).toList();
  } catch (e) {
    return [];
  }
}
