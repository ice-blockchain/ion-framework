// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class UserNameTile extends ConsumerWidget {
  const UserNameTile({
    required this.pubkey,
    this.profileMode = ProfileMode.light,
    this.showProfileTokenPrice = false,
    this.priceUsd,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.isDecoratedNichname = false,
    super.key,
  });

  double get verifiedIconSize => 16.0.s;

  final String pubkey;
  final ProfileMode profileMode;
  final bool showProfileTokenPrice;
  final double? priceUsd;
  final MainAxisAlignment mainAxisAlignment;
  final bool isDecoratedNichname;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    final isUserVerified = ref.watch(isUserVerifiedProvider(pubkey));
    final isNicknameProven = ref.watch(isNicknameProvenProvider(pubkey));

    if (userPreviewData == null) {
      return const SizedBox.shrink();
    }

    final nichnameWidget = Text(
      prefixUsername(
        input: (!isNicknameProven)
            ? '${userPreviewData.data.name} ${context.i18n.nickname_not_owned_suffix}'
            : userPreviewData.data.name,
        textDirection: Directionality.of(context),
      ),
      style: context.theme.appTextThemes.caption.copyWith(
        color: profileMode == ProfileMode.dark
            ? context.theme.appColors.secondaryBackground
            : context.theme.appColors.quaternaryText,
      ),
      maxLines: 1,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            Flexible(
              child: Text(
                textAlign: isDecoratedNichname ? TextAlign.left : TextAlign.center,
                userPreviewData.data.trimmedDisplayName,
                style: context.theme.appTextThemes.subtitle.copyWith(
                  color: profileMode == ProfileMode.dark
                      ? context.theme.appColors.secondaryBackground
                      : context.theme.appColors.primaryText,
                ),
              ),
            ),
            if (isUserVerified)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 4.0.s),
                child: Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
              ),
          ],
        ),
        SizedBox(height: 3.0.s),
        Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            if (isDecoratedNichname)
              Container(
                decoration: ShapeDecoration(
                  color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0.s),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.0.s,
                    vertical: 2.0.s,
                  ),
                  child: nichnameWidget,
                ),
              ),
            if (!isDecoratedNichname) nichnameWidget,
            if (showProfileTokenPrice && priceUsd != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 8.0.s),
                child: ProfileTokenPrice(
                  amount: priceUsd!,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
