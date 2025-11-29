import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/pages/holders/components/holder_tile.dart';
import 'package:ion/app/features/communities/pages/holders/components/top_holders/components/top_holders_skeleton.dart';
import 'package:ion/app/features/communities/pages/holders/providers/token_top_holders_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class HoldersPage extends HookConsumerWidget {
  const HoldersPage({required this.externalAddress, super.key});

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = useState(20);
    final topHoldersAsync = ref.watch(tokenTopHoldersProvider(externalAddress, limit: limit.value));

    final previousTopHolders = useRef<List<TopHolder>>([]);

    final topHolders =
        topHoldersAsync.isLoading ? previousTopHolders.value : topHoldersAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.holders, style: context.theme.appTextThemes.subtitle2),
      ),
      body: Column(
        children: [
          const SimpleSeparator(),
          Expanded(
            child: LoadMoreBuilder(
              slivers: [
                if (topHoldersAsync.isLoading && previousTopHolders.value.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.s, vertical: 12.s),
                      child: TopHoldersSkeleton(count: 20, seperatorHeight: 14.s),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: topHolders.length,
                    itemBuilder: (context, index) {
                      final topPadding = index == 0 ? 12.s : 7.s;
                      final bottomPadding = 7.s;
                      return _HolderListItem(
                        holder: topHolders[index],
                        topPadding: topPadding,
                        bottomPadding: bottomPadding,
                      );
                    },
                  ),
              ],
              onLoadMore: () async {
                if (topHoldersAsync.isLoading) return;
                previousTopHolders.value = topHolders;
                limit.value += 20;
              },
              hasMore: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HolderListItem extends StatelessWidget {
  const _HolderListItem({
    required this.holder,
    required this.topPadding,
    required this.bottomPadding,
  });

  final TopHolder holder;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: topPadding,
        bottom: bottomPadding,
        start: 16.s,
        end: 16.s,
      ),
      child: HolderTile(
        holder: holder,
      ),
    );
  }
}
