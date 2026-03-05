// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/providers/feed_search_categories.r.dart';
import 'package:ion/app/features/search/views/components/advanced_search_navigation/advanced_search_navigation.dart';
import 'package:ion/app/features/search/views/components/advanced_search_tab_bar/advanced_search_tab_bar.dart';
import 'package:ion/app/features/search/views/pages/feed_advanced_search_page/components/feed_advanced_search_posts/feed_advanced_search_posts.dart';
import 'package:ion/app/features/search/views/pages/feed_advanced_search_page/components/feed_advanced_search_users/feed_advanced_search_users.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class FeedAdvancedSearchPage extends ConsumerStatefulWidget {
  const FeedAdvancedSearchPage({required this.query, super.key});

  final String query;

  @override
  ConsumerState<FeedAdvancedSearchPage> createState() => _FeedAdvancedSearchPageState();
}

class _FeedAdvancedSearchPageState extends ConsumerState<FeedAdvancedSearchPage>
    with TickerProviderStateMixin, RestorationMixin {
  late TabController _tabController;
  final RestorableInt _tabIndex = RestorableInt(0);

  @override
  String? get restorationId => 'feed_advanced_search_tab';

  @override
  void initState() {
    super.initState();
    final categories = ref.read(searchCategoriesProvider);
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _tabIndex.value = _tabController.index;
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tabIndex, 'tab_index');
    _tabController.index = _tabIndex.value.clamp(0, _tabController.length - 1);
  }

  void _syncTabControllerLength(int newLength) {
    if (_tabController.length == newLength) return;
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    final clampedIndex = _tabIndex.value.clamp(0, newLength - 1);
    _tabController = TabController(
      length: newLength,
      vsync: this,
      initialIndex: clampedIndex,
    )..addListener(_onTabChanged);
    _tabIndex.value = clampedIndex;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(searchCategoriesProvider);
    _syncTabControllerLength(categories.length);

    return Scaffold(
      body: ScreenTopOffset(
        child: Column(
          children: [
            AdvancedSearchNavigation(
              query: widget.query,
              onTapSearch: (text) {
                FeedSimpleSearchRoute(query: text).push<void>(context);
              },
              onFiltersPressed: () {
                FeedSearchFiltersRoute().push<void>(context);
              },
            ),
            SizedBox(height: 16.0.s),
            AdvancedSearchTabBar(
              controller: _tabController,
              categories: categories,
            ),
            const SectionSeparator(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((category) {
                  return switch (category) {
                    AdvancedSearchCategory.trending ||
                    AdvancedSearchCategory.top ||
                    AdvancedSearchCategory.latest ||
                    AdvancedSearchCategory.photos ||
                    AdvancedSearchCategory.videos =>
                      FeedAdvancedSearchPosts(query: widget.query, category: category),
                    AdvancedSearchCategory.people => FeedAdvancedSearchUsers(query: widget.query),
                    _ => const SizedBox.shrink(),
                  };
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
