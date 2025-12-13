// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_header.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class CommunityTokenLiveBody extends HookConsumerWidget {
  const CommunityTokenLiveBody({
    required this.entity,
    super.key,
  });

  final CommunityTokenDefinitionEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenMarketInfo =
        ref.watch(tokenMarketInfoProvider(entity.data.externalAddress)).valueOrNull;
    final height = 329.s;

    if (tokenMarketInfo == null) {
      return SizedBox(height: height);
    }

    final avatarColors = useImageColors(tokenMarketInfo.imageUrl);

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0.s),
          child: ProfileBackground(
            colors: avatarColors,
            child: Center(
              child: TokenHeader(
                type: TokenHeaderType.feed,
                token: tokenMarketInfo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
