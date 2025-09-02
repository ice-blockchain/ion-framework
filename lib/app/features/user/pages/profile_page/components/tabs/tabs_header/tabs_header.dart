// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_content_type.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/tabs_header/tabs_header_tab.dart';

class ProfileTabsHeader extends HookConsumerWidget {
  const ProfileTabsHeader({
    required this.pageController,
    super.key,
  });

  final PageController pageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = DefaultTabController.of(context);
    final isTabTap = useRef(false);

    useEffect(
      () {
        void onPageChanged() {
          if (pageController.hasClients && !isTabTap.value) {
            final page = pageController.page?.round() ?? 0;

            if (tabController.index != page) {
              tabController.animateTo(page, duration: kThemeAnimationDuration);
            }
          }
        }

        pageController.addListener(onPageChanged);

        return () {
          pageController.removeListener(onPageChanged);
        };
      },
      [pageController, tabController],
    );

    return TabBar(
      controller: tabController,
      onTap: (index) async {
        isTabTap.value = true;
        tabController.animateTo(index);
        await pageController.animateToPage(
          index,
          duration: kThemeAnimationDuration,
          curve: Curves.easeIn,
        );
        isTabTap.value = false;
      },
      padding: EdgeInsets.symmetric(horizontal: 6.0.s),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 10.0.s),
      labelColor: context.theme.appColors.primaryAccent,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: UserContentType.values.map((tabType) {
        return ProfileTabsHeaderTab(
          tabType: tabType,
        );
      }).toList(),
      indicatorColor: context.theme.appColors.primaryAccent,
      dividerHeight: 0,
    );
  }
}
