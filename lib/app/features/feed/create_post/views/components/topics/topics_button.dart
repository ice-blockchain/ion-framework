// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/tag_button.dart';
import 'package:ion/app/components/showcase/showcase_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/views/components/topics/topics_button_tooltip.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/providers/topic_tooltip_visibility_notifier.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:showcaseview/showcaseview.dart';

class TopicsButton extends HookConsumerWidget {
  const TopicsButton({
    required this.type,
    super.key,
  });

  final FeedType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsButtonKey = useRef(GlobalKey());
    final topicsTooltipVisible = ref.watch(topicTooltipVisibilityNotifierProvider).falseOrValue;
    final availableInterests = ref.watch(
      feedUserInterestsProvider(type).select((state) => state.valueOrNull),
    );
    final availableCategories = availableInterests?.categories ?? {};
    final availableSubcategories = availableInterests?.subcategories ?? {};
    final availableCategoriesAndSubcategories = {
      ...availableCategories,
      ...availableSubcategories,
    };
    final selectedSubcategoriesKeys = ref.watch(selectedInterestsNotifierProvider);
    final selectedSubcategories =
        selectedSubcategoriesKeys.map((key) => availableSubcategories[key]).nonNulls.toList();

    useOnInit(
      () {
        if (!topicsTooltipVisible || !context.mounted) return;
        ShowCaseWidget.of(context).startShowCase(
          [topicsButtonKey.value],
        );
      },
      [topicsTooltipVisible],
    );

    useEffect(
      () {
        if (availableCategoriesAndSubcategories.isEmpty || selectedSubcategories.isEmpty) {
          return null;
        }
        final selectedSubcategoriesKeysSet = selectedSubcategoriesKeys.toSet();
        final selectedAvailableKeys = selectedSubcategoriesKeysSet
            .intersection({...availableCategoriesAndSubcategories.keys});
        final setsAreEqual = const SetEquality<String>().equals(
          selectedAvailableKeys,
          selectedSubcategoriesKeysSet,
        );
        if (!setsAreEqual) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ref.read(selectedInterestsNotifierProvider.notifier).interests =
                selectedAvailableKeys,
          );
        }
        return null;
      },
      [availableSubcategories],
    );

    return ShowcaseWrapper(
      showcaseKey: topicsButtonKey.value,
      tooltipWidth: 295.s,
      tooltipBuilder: (context, arrow) => TopicsButtonTooltip(
        arrow: arrow,
      ),
      targetBorderRadius: BorderRadius.circular(14.s),
      onDismissed: () {
        ref.read(topicTooltipVisibilityNotifierProvider.notifier).hide();
      },
      onTap: () {
        ref.read(topicTooltipVisibilityNotifierProvider.notifier).hide();
        _onTap(context);
      },
      child: TagButton(
        onPressed: () => _onTap(context),
        label: selectedSubcategories.isEmpty
            ? context.i18n.create_post_add_topic
            : selectedSubcategories.map((topic) => topic.display).join(', '),
        leadingIcon: Assets.svg.walletChannelPrivate,
      ),
    );
  }

  void _onTap(BuildContext context) {
    SelectTopicsRoute(feedType: type).push<void>(context);
  }
}
