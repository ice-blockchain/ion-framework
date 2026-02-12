// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class RepostAuthorHeader extends ConsumerWidget {
  const RepostAuthorHeader({required this.pubkey, super.key});

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(isCurrentUserSelectorProvider(pubkey))
        ? context.i18n.feed_you_reposted
        : context.i18n.feed_someone_reposted(
            ref.watch(userPreviewDataProvider(pubkey).select(userPreviewDisplayNameSelector)),
          );

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 12.0.s),
      child: GestureDetector(
        onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
        child: Row(
          children: [
            Assets.svg.iconFeedRepost.icon(
              size: 16.0.s,
              color: context.theme.appColors.onTertiaryBackground,
            ),
            SizedBox(width: 4.0.s),
            Flexible(
              child: Text(
                text,
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.onTertiaryBackground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
