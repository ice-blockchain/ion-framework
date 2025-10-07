// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/views/components/reply_input_field/reply_input_field.dart';
import 'package:ion/app/features/feed/data/models/analytics_events.dart';
import 'package:ion/app/features/feed/providers/can_reply_notifier.r.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/feed/views/components/reply_list/reply_list.dart';
import 'package:ion/app/features/feed/views/components/scroll_to_top_button/scroll_to_top_button.dart';
import 'package:ion/app/features/feed/views/components/time_ago/time_ago.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/services/analytics_service/analytics_service_provider.r.dart';

class PostDetailsPage extends HookConsumerWidget {
  const PostDetailsPage({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReply = ref.watch(canReplyProvider(eventReference)).value ?? false;
    final scrollController = useScrollController();

    useOnInit(() {
      ref.read(analyticsServiceProvider).logEvent(PostViewAnalyticsEvent(eventReference));
    });

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.post_page_title),
      ),
      body: Column(
        children: [
          Flexible(
            child: Stack(
              children: [
                ReplyList(
                  eventReference: eventReference,
                  scrollController: scrollController,
                  onPullToRefresh: () {
                    ref.read(ionConnectCacheProvider.notifier).remove(
                          CacheableEntity.cacheKeyBuilder(
                            eventReference: eventReference,
                          ),
                        );
                  },
                  headers: [
                    SliverToBoxAdapter(
                      child: Post(
                        eventReference: eventReference,
                        timeFormat: TimestampFormat.detailed,
                        onDelete: context.pop,
                        isTextSelectable: true,
                        bodyMaxLines: null,
                        displayParent: true,
                        showNotInterested: false,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SectionSeparator()),
                  ],
                ),
                PositionedDirectional(
                  bottom: 12.5.s,
                  end: 16.0.s,
                  child: ScrollToTopButton(
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
          ),
          if (canReply) ...[
            const HorizontalSeparator(),
            ReplyInputField(eventReference: eventReference),
          ],
        ],
      ),
    );
  }
}
