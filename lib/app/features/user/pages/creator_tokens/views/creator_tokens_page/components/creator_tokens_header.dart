// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/tabs_header/tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel_skeleton.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensHeader extends ConsumerWidget {
  const CreatorTokensHeader({
    required this.expandedHeight,
    required this.tabBarHeight,
    required this.opacity,
    required this.featuredTokensAsync,
    required this.selectedToken,
    required this.avatarColors,
    required this.backButtonIcon,
    required this.onPop,
    required this.onSearchToggle,
    this.scrollController,
    super.key,
  });

  final double expandedHeight;
  final double tabBarHeight;
  final double opacity;
  final AsyncValue<List<CommunityToken>> featuredTokensAsync;
  final ValueNotifier<CommunityToken?> selectedToken;
  final AvatarColors? avatarColors;
  final Widget backButtonIcon;
  final VoidCallback onPop;
  final VoidCallback onSearchToggle;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      toolbarHeight: NavigationAppBar.screenHeaderHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: NavigationBackButton(
        onPop,
        icon: backButtonIcon,
      ),
      flexibleSpace: Builder(
        builder: (context) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: ProfileBackground(
                  colors: avatarColors,
                ),
              ),
              Opacity(
                opacity: 1 - opacity,
                child: featuredTokensAsync.when(
                  data: (tokens) {
                    if (tokens.isEmpty) return const SizedBox.shrink();

                    return CreatorTokensCarousel(
                      tokens: tokens,
                      onItemChanged: (token) {
                        selectedToken.value = token;
                      },
                    );
                  },
                  loading: () => const CreatorTokensCarouselSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(tabBarHeight),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: TabsHeader(
            tabs: CreatorTokensTabType.values,
            trailing: _SearchIconButton(
              onPressed: onSearchToggle,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 4.0.s,
        horizontal: 16.0.s,
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Assets.svg.iconFieldSearch.icon(
          color: context.theme.appColors.tertiaryText,
          size: 18.0.s,
        ),
      ),
    );
  }
}
