// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';

class CommunityTokenLiveBody extends HookConsumerWidget {
  const CommunityTokenLiveBody({
    required this.entity,
    this.sidePadding,
    super.key,
  });

  final CommunityTokenDefinitionEntity entity;

  final double? sidePadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(tokenTypeForTokenDefinitionProvider(entity)).valueOrNull;

    if (type == null) {
      return const SizedBox.shrink();
    }

    if (type == CommunityContentTokenType.profile) {
      return FeedProfileToken(
        externalAddress: entity.data.externalAddress,
        sidePadding: sidePadding,
      );
    } else if (type == CommunityContentTokenType.twitter) {
      return FeedTwitterToken(
        externalAddress: entity.data.externalAddress,
        sidePadding: sidePadding,
      );
    } else if (type == CommunityContentTokenType.postText ||
        type == CommunityContentTokenType.postImage ||
        type == CommunityContentTokenType.postVideo ||
        type == CommunityContentTokenType.article) {
      return FeedContentToken(
        type: type,
        tokenDefinition: entity,
        sidePadding: sidePadding,
      );
    }

    return const SizedBox.shrink();
  }
}
