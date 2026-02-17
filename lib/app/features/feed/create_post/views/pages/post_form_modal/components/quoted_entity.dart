// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/article/article.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';
import 'package:ion/app/features/feed/views/components/quoted_entity_frame/quoted_entity_frame.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class QuotedEntity extends HookConsumerWidget {
  const QuotedEntity({
    required this.eventReference,
    this.trailing,
    super.key,
  });

  final EventReference eventReference;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ionConnectEntity =
        ref.watch(ionConnectSyncEntityWithCountersProvider(eventReference: eventReference));

    if (ionConnectEntity == null) {
      return const Skeleton(child: PostSkeleton());
    }

    final quoteChild = useMemoized(
      () {
        switch (ionConnectEntity) {
          case ModifiablePostEntity():
            return QuotedEntityFrame.post(
              child: Post(
                eventReference: eventReference,
                displayQuote: false,
                header: UserInfo(
                  pubkey: eventReference.masterPubkey,
                  trailing: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: ScreenSideOffset.defaultSmallMargin,
                    ),
                    child: trailing,
                  ),
                  padding: EdgeInsetsDirectional.only(
                    start: ScreenSideOffset.defaultSmallMargin,
                    top: ScreenSideOffset.defaultSmallMargin,
                  ),
                ),
                footer: const SizedBox.shrink(),
              ),
            );
          case ArticleEntity():
            return _TrailingOverlay(
              trailing: trailing,
              child: QuotedEntityFrame.article(
                child: Article.quoted(eventReference: eventReference),
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
      [ionConnectEntity, trailing],
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(start: 40.0.s, top: 16.0.s),
      child: quoteChild,
    );
  }
}

class _TrailingOverlay extends StatelessWidget {
  const _TrailingOverlay({required this.child, this.trailing});

  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (trailing == null) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: ScreenSideOffset.defaultSmallMargin,
          end: ScreenSideOffset.defaultSmallMargin,
          child: trailing!,
        ),
      ],
    );
  }
}
