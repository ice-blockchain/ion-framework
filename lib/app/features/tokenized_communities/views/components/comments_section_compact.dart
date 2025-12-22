// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/empty_list/empty_list.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/components/post_list_item.dart';
import 'package:ion/app/features/components/entities_list/list_entity_helper.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/can_reply_notifier.r.dart';
import 'package:ion/app/features/feed/providers/counters/replies_count_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_comments_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_comment_input_field/token_comment_input_field.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CommentsSectionCompact extends HookConsumerWidget {
  const CommentsSectionCompact({
    required this.tokenDefinitionEventReference,
    this.onTitleVisibilityChanged,
    this.onCommentInputFocusChanged,
    super.key,
  });

  final EventReference tokenDefinitionEventReference;
  final ValueChanged<double>? onTitleVisibilityChanged;
  final ValueChanged<bool>? onCommentInputFocusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;
    final commentInputKey = useRef(GlobalKey());

    final comments = ref.watch(tokenCommentsProvider(tokenDefinitionEventReference));
    final entities = comments?.data.items;
    final isLoading = comments?.data is PagedLoading;
    final hasData = comments?.data is PagedData;
    final isInitialLoad = entities == null && !hasData;


    final repliesCount = ref.watch(repliesCountProvider(tokenDefinitionEventReference, network: true),).valueOrNull;
    final hasMore = comments?.hasMore ?? false;
    final canReply =
        ref.watch(canReplyProvider(tokenDefinitionEventReference)).valueOrNull ?? false;
    final isLoadingMore = useRef(false);

    // Use Scrollable.of to access parent scroll controller
    useEffect(
      () {
        if (!hasMore) return null;

        VoidCallback? removeListener;

        // Try to find the scrollable ancestor
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final scrollable = Scrollable.maybeOf(context);
          if (scrollable == null) return;

          final scrollPosition = scrollable.position;
          if (!scrollPosition.hasContentDimensions) return;

          void checkScrollPosition() {
            if (!hasMore || isLoadingMore.value || isLoading) return;

            final distanceToBottom = scrollPosition.maxScrollExtent - scrollPosition.pixels;
            const loadMoreOffset = 200.0;

            if (distanceToBottom <= loadMoreOffset && !isLoadingMore.value) {
              isLoadingMore.value = true;
              ref
                  .read(tokenCommentsProvider(tokenDefinitionEventReference).notifier)
                  .loadMore(tokenDefinitionEventReference)
                  .whenComplete(() {
                isLoadingMore.value = false;
              });
            }
          }

          scrollPosition.addListener(checkScrollPosition);
          removeListener = () {
            scrollPosition.removeListener(checkScrollPosition);
          };
        });

        return () {
          removeListener?.call();
        };
      },
      [hasMore, isLoading, tokenDefinitionEventReference],
    );

    final titleRow = Row(
      children: [
        Assets.svg.iconBlockComment.icon(size: 18.0.s, color: colors.onTertiaryBackground),
        SizedBox(width: 6.0.s),
        Text(
          '${i18n.common_comments} ($repliesCount)',
          style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
        ),
      ],
    );

    return ColoredBox(
      color: colors.secondaryBackground,
      child: GestureDetector(
        onTap: () {
          // Unfocus when tapping outside the input field
          // TextFieldTapRegion will prevent this from firing when tapping on the input
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onTitleVisibilityChanged != null)
                    VisibilityDetector(
                      key: UniqueKey(),
                      onVisibilityChanged: (info) {
                        onTitleVisibilityChanged?.call(info.visibleFraction);
                      },
                      child: titleRow,
                    )
                  else
                    titleRow,
                ],
              ),
            ),
            if (canReply)
              TokenCommentInputField(
                key: commentInputKey.value,
                tokenDefinitionEventReference: tokenDefinitionEventReference,
                onFocusChanged: (bool isFocused) {
                  onCommentInputFocusChanged?.call(isFocused);
                  if (isFocused) {
                    // Scroll to input when focused and keyboard appears
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (!context.mounted) return;
                      final inputContext = commentInputKey.value.currentContext;
                      if (inputContext != null) {
                        Scrollable.ensureVisible(
                          inputContext,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: 0.4,
                        );
                      }
                    });
                  }
                },
              ),
            // Comments list
            if (isInitialLoad || (isLoading && entities == null))
              Padding(
                padding: EdgeInsets.all(16.0.s),
                child: const _CommentsSkeleton(),
              )
            else if (entities != null && entities.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entities.length,
                itemBuilder: (context, index) {
                  return _CommentItem(
                    eventReference: entities.elementAt(index).toEventReference(),
                  );
                },
              )
            else if (hasData)
              const _EmptyState(),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0.s),
      child: EmptyList(
        asset: Assets.svg.walletIconWalletEmptypost,
        title: context.i18n.tokenized_community_comments_empty,
      ),
    );
  }
}

class _CommentsSkeleton extends StatelessWidget {
  const _CommentsSkeleton();

  static const int numberOfItems = 4;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: SeparatedColumn(
        separator: const SectionSeparator(),
        children: List.generate(
          numberOfItems,
          (_) => ScreenSideOffset.small(child: const PostSkeleton()),
        ).toList(),
      ),
    );
  }
}

class _CommentItem extends ConsumerWidget {
  const _CommentItem({
    required this.eventReference,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity =
        ref.watch(ionConnectEntityWithCountersProvider(eventReference: eventReference)).valueOrNull;

    if (entity == null ||
        ListEntityHelper.isUserMuted(ref, entity.masterPubkey, showMuted: false) ||
        ListEntityHelper.isUserBlockedOrBlocking(context, ref, entity) ||
        ListEntityHelper.isEntityOrRepostedEntityDeleted(context, ref, entity)) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          top: BorderSide(
            width: 1.0.s,
            color: context.theme.appColors.primaryBackground,
          ),
          bottom: BorderSide(
            width: 1.0.s,
            color: context.theme.appColors.primaryBackground,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: 1.0.s),
        child: switch (entity) {
          ModifiablePostEntity() || PostEntity() => PostListItem(
              eventReference: entity.toEventReference(),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
