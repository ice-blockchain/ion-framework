// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/hooks/use_watch_when_visible.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TokenCardBuilder extends HookConsumerWidget {
  const TokenCardBuilder({
    required this.externalAddress,
    required this.skeleton,
    required this.builder,
    super.key,
  });

  final String externalAddress;
  final Widget skeleton;
  final Widget Function(CommunityToken token, AvatarColors colors) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = useWatchWhenVisible(
          watcher: () => ref.watch(
            tokenMarketInfoProvider(externalAddress).select((value) {
              final token = value.valueOrNull;
              if (token != null) {
                ListCachedObjects.updateObject<CommunityToken>(context, token);
              }
              return token;
            }),
          ),
        ) ??
        ListCachedObjects.maybeObjectOf<CommunityToken>(context, externalAddress);

    final colors = useImageColors(token?.imageUrl);
    if (token == null || colors == null) return skeleton;

    return builder(token, colors);
  }
}
