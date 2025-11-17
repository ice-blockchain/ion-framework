// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/feed/data/models/feed_category.dart';
import 'package:ion/app/features/feed/providers/counters/helpers/counter_cache_helpers.r.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_trending_videos_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/current_user_feed_story_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/article_categories_menu/article_categories_menu.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_filters/feed_filters_menu_button.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_navigation/feed_navigation.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_navigation/feed_notifications_button.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/feed_controls.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_posts_list/feed_posts_list.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/stories.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/trending_videos.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/settings/providers/test_follow_list_provider.r.dart';
import 'package:ion/app/features/settings/providers/test_post_deletion_provider.r.dart';
import 'package:ion/app/features/settings/providers/test_post_provider.r.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/components/navigation_app_bar/collapsing_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class FeedPage extends HookConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedCategory = ref.watch(feedCurrentFilterProvider.select((state) => state.category));
    final hasMorePosts = ref.watch(feedPostsProvider.select((state) => state.hasMore)).falseOrValue;
    final showTrendingVideosFeatureFlag = useRef(
      ref.watch(featureFlagsProvider.notifier).get(FeedFeatureFlag.showTrendingVideo),
    );
    final scrollController = useScrollController();

    useScrollTopOnTabPress(context, scrollController: scrollController);

    final showStories = feedCategory != FeedCategory.articles;
    final showTrendingVideos = showTrendingVideosFeatureFlag.value &&
        (feedCategory == FeedCategory.feed || feedCategory == FeedCategory.videos);

    final slivers = [
      if (showTrendingVideos)
        const SliverToBoxAdapter(
          child: TrendingVideos(),
        ),
      const FeedPostsList(),
    ];

    return Scaffold(
      appBar: NavigationAppBar.root(
        title: const FeedNavigation(),
        actions: [
          SizedBox(width: 12.0.s),
          const FeedNotificationsButton(),
          SizedBox(width: 12.0.s),
          FeedFiltersMenuButton(scrollController: scrollController),

          // SizedBox(width: 12.0.s),
          // const _DebugTestPostDeletionSelectedRelayButton(),
          // SizedBox(width: 12.0.s),
          // const _DebugTestPostDeletionAllRelaysButton(),
          SizedBox(width: 12.0.s),
          const _DebugTestPostSelectedRelayButton(),
          SizedBox(width: 12.0.s),
          const _DebugTestPostAllRelaysButton(),
        ],
        scrollController: scrollController,
        horizontalPadding: ScreenSideOffset.defaultSmallMargin,
      ),
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: LoadMoreBuilder(
          slivers: slivers,
          hasMore: hasMorePosts,
          onLoadMore: () => _onLoadMore(ref),
          builder: (context, slivers) {
            return PullToRefreshBuilder(
              sliverAppBar: CollapsingAppBar(
                height: Stories.height,
                bottomOffset: 0,
                topOffset: 8.0.s,
                child: Column(
                  children: [
                    if (feedCategory == FeedCategory.articles) const ArticleCategoriesMenu(),
                    if (showStories) const Stories(),
                  ],
                ),
              ),
              slivers: slivers,
              onRefresh: () =>
                  _onRefresh(ref, showStories: showStories, showTrendingVideos: showTrendingVideos),
              refreshIndicatorEdgeOffset: FeedControls.height +
                  MediaQuery.paddingOf(context).top +
                  ScreenTopOffset.defaultMargin,
              builder: (context, slivers) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
                controller: scrollController,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onLoadMore(WidgetRef ref) async {
    return ref.read(feedPostsProvider.notifier).fetchEntities();
  }

  Future<void> _onRefresh(
    WidgetRef ref, {
    required bool showStories,
    required bool showTrendingVideos,
  }) async {
    final currentFeedItems = ref.read(feedPostsProvider).items;
    if (currentFeedItems != null) {
      final eventReferences = currentFeedItems.map((entity) => entity.toEventReference());
      ref.read(quoteCounterUpdaterProvider).invalidateReactionCachesForEvents(eventReferences);
    }
    ref.read(feedPostsProvider.notifier).refresh();
    if (showTrendingVideos) {
      ref.read(feedTrendingVideosProvider.notifier).refresh();
    }
    if (showStories) {
      ref.read(feedStoriesProvider.notifier).refresh();
      ref.read(currentUserFeedStoryProvider.notifier).refresh();
    }
  }
}

class _DebugTestSelectedRelayButton extends ConsumerStatefulWidget {
  const _DebugTestSelectedRelayButton();

  @override
  ConsumerState<_DebugTestSelectedRelayButton> createState() => _DebugTestSelectedRelayButtonState();
}

class _DebugTestSelectedRelayButtonState extends ConsumerState<_DebugTestSelectedRelayButton> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.settings_ethernet),
      tooltip: 'Test Follow List on Selected Relay',
      onPressed: _isTesting
          ? null
          : () async {
              setState(() => _isTesting = true);
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing follow list on selected relay... Check logs for details.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                final result = await ref.read(
                  testFollowListOnSelectedRelayProvider.future,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result != null
                            ? 'Success! Event ID: ${result.id.substring(0, 16)}...'
                            : 'Failed to fetch back event. Check logs for details.',
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isTesting = false);
                }
              }
            },
    );
  }
}

class _DebugTestFollowButton extends ConsumerStatefulWidget {
  const _DebugTestFollowButton();

  @override
  ConsumerState<_DebugTestFollowButton> createState() => _DebugTestFollowButtonState();
}

class _DebugTestFollowButtonState extends ConsumerState<_DebugTestFollowButton> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bug_report),
      tooltip: 'Test Follow List on All Relays',
      onPressed: _isTesting
          ? null
          : () async {
              setState(() => _isTesting = true);
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing follow list on all relays... Check logs for detailed report.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                final reports = await ref.read(
                  testFollowListOnAllRelaysProvider.future,
                );

                if (context.mounted) {
                  final successful = reports.where((r) => r.success).length;
                  final matched = reports.where((r) => r.matched).length;
                  final failed = reports.where((r) => !r.success).length;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Test completed! Success: $successful, Matched: $matched, Failed: $failed. Check logs for details.',
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isTesting = false);
                }
              }
            },
    );
  }
}

class _DebugTestPostDeletionSelectedRelayButton extends ConsumerStatefulWidget {
  const _DebugTestPostDeletionSelectedRelayButton();

  @override
  ConsumerState<_DebugTestPostDeletionSelectedRelayButton> createState() =>
      _DebugTestPostDeletionSelectedRelayButtonState();
}

class _DebugTestPostDeletionSelectedRelayButtonState
    extends ConsumerState<_DebugTestPostDeletionSelectedRelayButton> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline),
      tooltip: 'Test Post Deletion on Selected Relay',
      onPressed: _isTesting
          ? null
          : () async {
              setState(() => _isTesting = true);
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing post deletion on selected relay... Check logs for details.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                final result = await ref.read(
                  testPostDeletionOnSelectedRelayProvider.future,
                );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result != null
                            ? 'Success! Deletion Event ID: ${result.id.substring(0, 16)}...'
                            : 'Failed to fetch back deletion event. Check logs for details.',
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isTesting = false);
                }
              }
            },
    );
  }
}

class _DebugTestPostDeletionAllRelaysButton extends ConsumerStatefulWidget {
  const _DebugTestPostDeletionAllRelaysButton();

  @override
  ConsumerState<_DebugTestPostDeletionAllRelaysButton> createState() =>
      _DebugTestPostDeletionAllRelaysButtonState();
}

class _DebugTestPostDeletionAllRelaysButtonState
    extends ConsumerState<_DebugTestPostDeletionAllRelaysButton> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_sweep),
      tooltip: 'Test Post Deletion on All Relays',
      onPressed: _isTesting
          ? null
          : () async {
              setState(() => _isTesting = true);
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing post deletion on all relays... Check logs for detailed report.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                final reports = await ref.read(
                  testPostDeletionOnAllRelaysProvider.future,
                );

                if (context.mounted) {
                  final successful = reports.where((r) => r.success).length;
                  final matched = reports.where((r) => r.matched).length;
                  final failed = reports.where((r) => !r.success).length;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Test completed! Success: $successful, Matched: $matched, Failed: $failed. Check logs for details.',
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isTesting = false);
                }
              }
            },
    );
  }
}

class _DebugTestPostSelectedRelayButton extends ConsumerStatefulWidget {
  const _DebugTestPostSelectedRelayButton();

  @override
  ConsumerState<_DebugTestPostSelectedRelayButton> createState() =>
      _DebugTestPostSelectedRelayButtonState();
}

class _DebugTestPostSelectedRelayButtonState
    extends ConsumerState<_DebugTestPostSelectedRelayButton> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.article_outlined),
      tooltip: 'Test Post on Selected Relay',
      onPressed: _isTesting
          ? null
          : () async {
              setState(() => _isTesting = true);
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing post on selected relay... Check logs for details.'),
                      duration: Duration(seconds: 3),
                    ),
            );
          }

          final result = await ref.read(
                  testPostOnSelectedRelayProvider.future,
          ) as EventMessage?;

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result != null
                            ? 'Success! Post ID: ${result.id.substring(0, 16)}...'
                            : 'Failed to fetch back post. Check logs for details.',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isTesting = false);
                }
              }
            },
    );
  }
}

class _DebugTestPostAllRelaysButton extends ConsumerStatefulWidget {
  const _DebugTestPostAllRelaysButton();

  @override
  ConsumerState<_DebugTestPostAllRelaysButton> createState() =>
      _DebugTestPostAllRelaysButtonState();
}

class _DebugTestPostAllRelaysButtonState
    extends ConsumerState<_DebugTestPostAllRelaysButton> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isTesting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.article),
      tooltip: 'Test Post on All Relays',
      onPressed: _isTesting
          ? null
          : () async {
              setState(() => _isTesting = true);
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing post on all relays... Check logs for detailed report.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                final reports = await ref.read(
                  testPostOnAllRelaysProvider.future,
                );

                if (context.mounted) {
                  final successful = reports.where((r) => r.success).length;
                  final matched = reports.where((r) => r.matched).length;
                  final failed = reports.where((r) => !r.success).length;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Test completed! Success: $successful, Matched: $matched, Failed: $failed. Check logs for details.',
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isTesting = false);
                }
        }
      },
    );
  }
}
