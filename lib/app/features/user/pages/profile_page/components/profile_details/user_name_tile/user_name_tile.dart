// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class UserNameTile extends ConsumerWidget {
  const UserNameTile({
    required this.pubkey,
    super.key,
  });

  double get verifiedIconSize => 16.0.s;

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataValue = ref.watch(userMetadataProvider(pubkey)).valueOrNull;
    final isUserVerified = ref.watch(isUserVerifiedProvider(pubkey));
    final isNicknameProven = ref.watch(isNicknameProvenProvider(pubkey));

    if (userMetadataValue == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                textAlign: TextAlign.center,
                userMetadataValue.data.trimmedDisplayName,
                style: context.theme.appTextThemes.subtitle.copyWith(
                  color: context.theme.appColors.primaryText,
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
        Text(
          prefixUsername(
            username: (!isNicknameProven)
                ? '${userMetadataValue.data.name} ${context.i18n.nickname_not_owned_suffix}'
                : userMetadataValue.data.name,
            context: context,
          ),
          style: context.theme.appTextThemes.caption.copyWith(
            color: context.theme.appColors.quaternaryText,
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
