// SPDX-License-Identifier: ice License 1.0

abstract class PagedSource {
  int get page;
  bool get hasMore;
}

/// Returns a map of the next page sources to fetch, up to the specified [limit].
///
/// This function selects sources from the [sources] map that have more pages to load
/// (`hasMore` is true). It prioritizes sources with the lowest current page number.
///
/// Returns a map containing entries of sources to fetch next.
Map<String, PagedSource> getNextPageSources({
  required Map<String, PagedSource> sources,
  required int limit,
}) {
  int? minPage;
  final selected = <MapEntry<String, PagedSource>>[];
  final remaining = <MapEntry<String, PagedSource>>[];

  for (final source in sources.entries) {
    if (!source.value.hasMore) continue;

    final page = source.value.page;

    if (page == minPage) {
      selected.add(source);
    } else if (minPage == null || page < minPage) {
      // Found a lower page, reset the selection
      minPage = page;
      remaining.addAll(selected);
      selected
        ..clear()
        ..add(source);
    } else {
      remaining.add(source);
    }
  }

  if (selected.length >= limit) {
    return Map.fromEntries(
      (selected..shuffle()).take(limit),
    );
  }

  if (selected.length < limit && remaining.isNotEmpty) {
    selected.addAll(
      getNextPageSources(
        sources: Map.fromEntries(remaining),
        limit: limit - selected.length,
      ).entries,
    );
  }

  return Map.fromEntries(selected..shuffle());
}
