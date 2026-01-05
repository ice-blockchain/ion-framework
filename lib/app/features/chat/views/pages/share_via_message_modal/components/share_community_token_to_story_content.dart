// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class ShareCommunityTokenToStoryContent extends HookConsumerWidget {
  const ShareCommunityTokenToStoryContent({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenDefinition =
        ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

    if (tokenDefinition == null || tokenDefinition is! CommunityTokenDefinitionEntity) {
      return const SizedBox.shrink();
    }

    final externalAddress = tokenDefinition.data.externalAddress;

    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

    final tokenType = ref.watch(tokenTypeForTokenDefinitionProvider(tokenDefinition)).valueOrNull;
    if (tokenInfo == null || tokenType == null) {
      return const SizedBox.shrink();
    }

    final avatarColors = useImageColors(tokenInfo.imageUrl);

    if (avatarColors == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ProfileBackground(
            colors: avatarColors,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: IntrinsicHeight(
                child: Builder(
                  builder: (context) {
                    if (tokenType == CommunityContentTokenType.twitter) {
                      return TwitterTokenHeader(
                        token: tokenInfo,
                      );
                    }
                    return ContentTokenHeader(
                      token: tokenInfo,
                      tokenDefinition: tokenDefinition,
                      type: tokenType,
                      externalAddress: externalAddress,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
