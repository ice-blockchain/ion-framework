// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenizedCommunityOnboardingDialogEvent extends UiEvent {
  const TokenizedCommunityOnboardingDialogEvent()
      : super(id: 'tokenized_community_onboarding_dialog');

  static bool shown = false;

  @override
  Future<void> performAction(BuildContext context) async {
    if (!shown) {
      shown = true;
      await showSimpleBottomSheet<void>(
        context: context,
        isDismissible: false,
        backgroundColor: context.theme.appColors.forest,
        child: const TokenizedCommunityOnboardingDialog(),
      ).whenComplete(() => shown = false);
    }
  }
}

class TokenizedCommunityOnboardingDialog extends HookConsumerWidget {
  const TokenizedCommunityOnboardingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileGradientBackground(
      colors: useAvatarFallbackColors,
      disableDarkGradient: false,
      child: const _TokenizedCommunityOnboarding(),
    );
  }
}

class _TokenizedCommunityOnboarding extends HookWidget {
  const _TokenizedCommunityOnboarding();

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);
    final pageController = usePageController(initialPage: currentIndex.value);

    final pages = useMemoized(
      () => [
        OnboardingPage(
          image: Assets.images.tokenizedCommunities.onboardingRewards,
          title: context.i18n.tokenized_community_onboarding_rewards_title,
          description: context.i18n.tokenized_community_onboarding_rewards_description,
        ),
        OnboardingPage(
          image: Assets.images.tokenizedCommunities.onboardingAds,
          title: context.i18n.tokenized_community_onboarding_ads_title,
          description: context.i18n.tokenized_community_onboarding_ads_description,
        ),
        OnboardingPage(
          image: Assets.images.tokenizedCommunities.onboardingSupport,
          title: context.i18n.tokenized_community_onboarding_support_title,
          description: context.i18n.tokenized_community_onboarding_support_description,
        ),
        OnboardingPage(
          image: Assets.images.tokenizedCommunities.onboardingWeb3,
          title: context.i18n.tokenized_community_onboarding_web3_title,
          description: context.i18n.tokenized_community_onboarding_web3_description,
        ),
      ],
    );

    return Stack(
      children: [
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: Assets.images.tokenizedCommunities.creatorMonetizationLiveRays
              .iconWithDimensions(width: 461.s, height: 461.s),
        ),
        Column(
          children: [
            SizedBox(height: 30.0.s),
            _OnboardingCarousel(
              pageController: pageController,
              onPageChanged: (index) => currentIndex.value = index,
              pages: pages,
            ),
            SizedBox(height: 16.0.s),
            _OnboardingProgress(
              currentIndex: currentIndex.value,
              total: pages.length,
            ),
            SizedBox(height: 32.0.s),
            ScreenSideOffset.small(
              child: Button(
                minimumSize: Size(double.infinity, 56.0.s),
                label: Text(context.i18n.button_continue),
                onPressed: () {
                  if (currentIndex.value == pages.length - 1) {
                    Navigator.of(context).pop();
                  } else {
                    pageController.animateToPage(
                      currentIndex.value + 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ],
    );
  }
}

class OnboardingPage {
  OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });

  final AssetGenImage image;
  final String title;
  final String description;
}

class _OnboardingCarousel extends StatelessWidget {
  const _OnboardingCarousel({
    required this.pages,
    required this.pageController,
    required this.onPageChanged,
  });

  final List<OnboardingPage> pages;
  final PageController pageController;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 274.0.s,
      child: AnimatedBuilder(
        animation: pageController,
        builder: (context, child) {
          return PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pageController.hasClients ? pageController.page ?? 0.0 : 0.0;
              final opacity = (1 - (page - index).abs()).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: _OnboardingCarouselPage(page: pages[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _OnboardingCarouselPage extends StatelessWidget {
  const _OnboardingCarouselPage({
    required this.page,
  });

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

    return ScreenSideOffset.small(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          page.image.iconWithDimensions(width: 295.s, height: 164.s),
          const Spacer(),
          Text(
            page.title,
            style: textStyles.title.copyWith(color: colors.secondaryBackground),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0.s),
          Text(
            page.description,
            style: textStyles.body2.copyWith(color: colors.onTertiaryFill),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0.s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 6.0.s,
            height: 6.0.s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == currentIndex ? colors.primaryAccent : colors.onTertiaryFill,
            ),
          ),
        ),
      ),
    );
  }
}
