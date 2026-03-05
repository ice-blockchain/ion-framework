// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/views/components/advanced_search_channels/advanced_search_channels.dart';
import 'package:ion/app/features/search/views/components/advanced_search_groups/advanced_search_groups.dart';
import 'package:ion/app/features/search/views/components/advanced_search_navigation/advanced_search_navigation.dart';
import 'package:ion/app/features/search/views/components/advanced_search_tab_bar/advanced_search_tab_bar.dart';
import 'package:ion/app/features/search/views/pages/chat/chat_advanced_search_page/components/chat_advanced_search_all/chat_advanced_search_all.dart';
import 'package:ion/app/features/search/views/pages/chat/chat_advanced_search_page/components/chat_advanced_search_chats/chat_advanced_search_chats.dart';
import 'package:ion/app/features/search/views/pages/chat/chat_advanced_search_page/components/chat_advanced_search_people/chat_advanced_search_people.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ChatAdvancedSearchPage extends ConsumerStatefulWidget {
  const ChatAdvancedSearchPage({required this.query, super.key});

  final String query;

  @override
  ConsumerState<ChatAdvancedSearchPage> createState() => _ChatAdvancedSearchPageState();
}

class _ChatAdvancedSearchPageState extends ConsumerState<ChatAdvancedSearchPage>
    with TickerProviderStateMixin, RestorationMixin {
  late TabController _tabController;
  final RestorableInt _tabIndex = RestorableInt(0);

  @override
  String? get restorationId => 'chat_advanced_search_tab';

  @override
  void initState() {
    super.initState();
    final categories = _computeCategories();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  List<AdvancedSearchCategory> _computeCategories() {
    final hideCommunity =
        ref.read(featureFlagsProvider.notifier).get(ChatFeatureFlag.hideCommunity);
    return AdvancedSearchCategory.values
        .where(
          (category) => category.isChat && (!hideCommunity || !category.isCommunity),
        )
        .toList();
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
    final hideCommunity =
        ref.watch(featureFlagsProvider.notifier).get(ChatFeatureFlag.hideCommunity);

    final categories = AdvancedSearchCategory.values
        .where(
          (category) => category.isChat && (!hideCommunity || !category.isCommunity),
        )
        .toList();

    _syncTabControllerLength(categories.length);

    return Scaffold(
      body: ScreenTopOffset(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdvancedSearchNavigation(
              query: widget.query,
              onTapSearch: (text) {
                ChatQuickSearchRoute(query: text).push<void>(context);
              },
            ),
            SizedBox(height: 16.0.s),
            AdvancedSearchTabBar(controller: _tabController, categories: categories),
            const SectionSeparator(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((category) {
                  return switch (category) {
                    AdvancedSearchCategory.all => ChatAdvancedSearchAll(query: widget.query),
                    AdvancedSearchCategory.people =>
                      ChatAdvancedSearchPeople(query: widget.query),
                    AdvancedSearchCategory.chat =>
                      ChatAdvancedSearchChats(query: widget.query),
                    AdvancedSearchCategory.groups => AdvancedSearchGroups(query: widget.query),
                    AdvancedSearchCategory.channels =>
                      AdvancedSearchChannels(query: widget.query),
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
