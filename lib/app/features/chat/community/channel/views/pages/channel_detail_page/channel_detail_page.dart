// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/channel/models/channel_detail_tab.dart';
import 'package:ion/app/features/chat/community/channel/views/components/channel_detail_app_bar.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/channel_detail_page/components/channel_detail_tabs_header.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/channel_detail_page/components/channel_summary.dart';
import 'package:ion/app/features/chat/community/providers/community_metadata_provider.r.dart';
import 'package:ion/app/features/user/model/user_content_type.dart';

class ChannelDetailPage extends ConsumerStatefulWidget {
  const ChannelDetailPage({
    required this.uuid,
    super.key,
  });

  final String uuid;

  @override
  ConsumerState<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends ConsumerState<ChannelDetailPage>
    with SingleTickerProviderStateMixin, RestorationMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;
  final RestorableInt _tabIndex = RestorableInt(0);

  @override
  String? get restorationId => 'channel_detail_tab';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(
      length: UserContentType.values.length,
      vsync: this,
    );
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
    _tabController.index = _tabIndex.value;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _scrollController.dispose();
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(communityMetadataProvider(widget.uuid)).valueOrNull;

    if (channel == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: ScreenTopOffset(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            NestedScrollView(
              restorationId: 'channel_detail_scroll',
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: ColoredBox(
                      color: context.theme.appColors.secondaryBackground,
                      child: ScreenSideOffset.small(
                        child: ChannelSummary(
                          channel: channel,
                        ),
                      ),
                    ),
                  ),
                  PinnedHeaderSliver(
                    child: ColoredBox(
                      color: context.theme.appColors.secondaryBackground,
                      child: SizedBox(height: 20.0.s),
                    ),
                  ),
                  PinnedHeaderSliver(
                    child: ColoredBox(
                      color: context.theme.appColors.secondaryBackground,
                      child: ChannelDetailTabsHeader(controller: _tabController),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: ChannelDetailTab.values
                    .map(
                      (type) => Container(),
                    )
                    .toList(),
              ),
            ),
            ChannelDetailAppBar(channel: channel.data),
          ],
        ),
      ),
    );
  }
}
