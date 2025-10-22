// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/tooltip/copied_tooltip.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/invite_friends_page/models/referral_summary_item.dart';
import 'package:ion/app/features/feed/views/pages/invite_friends_page/models/summary_item_type.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user/providers/user_social_profile_provider.r.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/app/services/clipboard/clipboard.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:share_plus/share_plus.dart';

part 'components/earnings_card.dart';
part 'components/ion_card.dart';
part 'components/percentage_card.dart';
part 'components/referral_code_card.dart';
part 'components/summary_card.dart';

class InviteFriendsPage extends HookConsumerWidget {
  const InviteFriendsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: 60.0.s);

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
    );
    final userMetadataValue = ref.watch(currentUserMetadataProvider).valueOrNull;
    final referralCode = userMetadataValue?.data.name;

    final userSocialProfile = ref.watch(currentUserSocialProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: UnconstrainedBox(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 270.0.s,
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(top: 26.0.s, bottom: 20.0.s),
                        child: InfoCard(
                          iconAsset: Assets.svg.iconFeedProfileInvite,
                          title: context.i18n.invite_friends_page_title,
                          description: context.i18n.invite_friends_page_subtitle,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      16.0.s,
                      0,
                      16.0.s,
                      94.0.s,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8.0.s,
                      children: [
                        Row(
                          spacing: 8.0.s,
                          children: [
                            Expanded(
                              child: _PercentageCard(
                                title: context.i18n.invite_friends_percentage_first_month_label,
                                percentage: 50,
                              ),
                            ),
                            Expanded(
                              child: _PercentageCard(
                                title: context.i18n.invite_friends_percentage_lifetime_label,
                                percentage: 10,
                              ),
                            ),
                          ],
                        ),
                        const _EarningsCard(),
                        _SummaryCard(userSocialProfile),
                        if (referralCode case final referralCode?)
                          _ReferralCodeCard(
                            referralCode: referralCode,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: opacity,
              child: NavigationAppBar(
                useScreenTopOffset: true,
                backButtonIcon: backButtonIcon,
                scrollController: scrollController,
                horizontalPadding: 0,
                title: Text(
                  context.i18n.invite_friends_button,
                  style: context.theme.appTextThemes.subtitle2.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: NavigationBackButton(
                context.pop,
                icon: backButtonIcon,
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.appColors.shadow.withAlpha(8),
                      blurRadius: 16.0.s,
                      offset: Offset(-2.0.s, -2.0.s),
                    ),
                  ],
                  color: context.theme.appColors.onPrimaryAccent,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
                child: Button(
                  leadingIcon: Assets.svg.iconButtonInvite.icon(
                    size: 24.0.s,
                    color: context.theme.appColors.onPrimaryAccent,
                  ),
                  label: Text(
                    context.i18n.invite_friends_button,
                    style: context.theme.appTextThemes.body,
                  ),
                  onPressed: () {
                    Share.share(
                      '${context.i18n.invite_friends_shared_link_text} https://online.io/@$referralCode',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
