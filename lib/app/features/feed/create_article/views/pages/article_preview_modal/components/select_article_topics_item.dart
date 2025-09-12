// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/showcase/showcase_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/views/components/topics_button/topics_button_tooltip.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/providers/topic_tooltip_visibility_notifier.r.dart';
import 'package:ion/app/features/feed/views/components/topics/topics_carousel.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:showcaseview/showcaseview.dart';

class SelectArticleTopicsItem extends HookConsumerWidget {
  const SelectArticleTopicsItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsButtonKey = useRef(GlobalKey());
    final topicsTooltipVisible = ref.watch(topicTooltipVisibilityNotifierProvider).falseOrValue;

    useOnInit(
      () {
        if (!topicsTooltipVisible || !context.mounted) return;
        ShowCaseWidget.of(context).startShowCase(
          [topicsButtonKey.value],
        );
      },
      [topicsTooltipVisible],
    );

    return Column(
      children: [
        ScreenSideOffset.medium(
          child: ShowcaseWrapper(
            showcaseKey: topicsButtonKey.value,
            tooltipWidth: 295.s,
            tooltipBuilder: (context, arrow) => TopicsButtonTooltip(
              arrow: arrow,
            ),
            targetBorderRadius: BorderRadius.circular(10.s),
            onDismissed: () {
              ref.read(topicTooltipVisibilityNotifierProvider.notifier).hide();
            },
            onTap: () {
              ref.read(topicTooltipVisibilityNotifierProvider.notifier).hide();
              _onTap(context);
            },
            child: ListItem(
              title: Text(
                context.i18n.topics_title,
                style: context.theme.appTextThemes.body.copyWith(
                  color: topicsTooltipVisible
                      ? context.theme.appColors.secondaryBackground
                      : context.theme.appColors.primaryText,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              backgroundColor: topicsTooltipVisible
                  ? context.theme.appColors.backgroundSheet.withAlpha(191)
                  : context.theme.appColors.secondaryBackground,
              borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
              leading: Container(
                width: 36.0.s,
                height: 36.0.s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.theme.appColors.tertiaryBackground,
                  borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
                  border: Border.all(
                    width: 1.0.s,
                    color: context.theme.appColors.onTertiaryFill,
                  ),
                ),
                child: Assets.svg.walletChannelPrivate
                    .icon(color: context.theme.appColors.primaryAccent),
              ),
              trailing: Assets.svg.iconArrowRight.icon(
                color: topicsTooltipVisible
                    ? context.theme.appColors.secondaryBackground
                    : context.theme.appColors.primaryText,
              ),
              constraints: BoxConstraints(minHeight: 40.0.s),
              onTap: () => _onTap(context),
            ),
          ),
        ),
        _Topics(
          padding: EdgeInsetsDirectional.only(top: 10.0.s),
        ),
      ],
    );
  }

  void _onTap(BuildContext context) {
    SelectTopicsRoute(feedType: FeedType.article).push<void>(context);
  }
}

class _Topics extends HookConsumerWidget {
  const _Topics({
    required this.padding,
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSubcategories = ref.watch(
      feedUserInterestsProvider(FeedType.article)
          .select((state) => state.valueOrNull?.subcategories ?? {}),
    );
    final selectedSubcategoriesKeys = ref.watch(selectedInterestsNotifierProvider);
    final topics = selectedSubcategoriesKeys
        .map((key) => availableSubcategories[key]?.display)
        .nonNulls
        .toList();

    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: TopicsCarousel(topics: topics),
    );
  }
}
