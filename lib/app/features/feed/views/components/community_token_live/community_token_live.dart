// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_button.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/post_menu_bottom_sheet.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/community_token_live_body.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/generated/assets.gen.dart';

class CommunityTokenLive extends HookConsumerWidget {
  const CommunityTokenLive({
    required this.eventReference,
    this.network = false,
    super.key,
  });

  final EventReference eventReference;

  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(
          ionConnectEntityWithCountersProvider(
            eventReference: eventReference,
            network: network,
          ).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));

    if (entity == null || entity is! CommunityTokenDefinitionEntity) {
      return ScreenSideOffset.small(
        child: const Skeleton(
          child: PostSkeleton(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entity.data.kind == UserMetadataEntity.kind &&
            entity.data.relatedHashtags.any((i) => i.value == communityTokenActionTopic)) ...[
          ScreenSideOffset.small(
            child: const _CreatorTokenIsLiveLabel(),
          ),
          SizedBox(height: 8.0.s),
        ],
        UserInfo(
          pubkey: eventReference.masterPubkey,
          network: network,
          createdAt: entity.createdAt,
          trailing: isOwnedByCurrentUser
              ? null
              : BottomSheetMenuButton(
                  menuBuilder: (context) => PostMenuBottomSheet(eventReference: eventReference),
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: ScreenSideOffset.defaultSmallMargin,
                    vertical: 5.0.s,
                  ),
                ),
          padding: EdgeInsetsDirectional.only(
            start: ScreenSideOffset.defaultSmallMargin,
          ),
        ),
        SizedBox(height: 10.0.s),
        CommunityTokenLiveBody(entity: entity),
        CounterItemsFooter(eventReference: eventReference),
      ],
    );
  }
}

class _CreatorTokenIsLiveLabel extends StatelessWidget {
  const _CreatorTokenIsLiveLabel();

  @override
  Widget build(BuildContext context) {
    final color = context.theme.appColors.onTertiaryBackground;
    return Row(
      children: [
        Assets.svg.iconCreatecoinNewcoin.icon(size: 16.0.s, color: color),
        SizedBox(width: 4.0.s),
        Text(
          context.i18n.creator_token_is_live,
          style: context.theme.appTextThemes.body2.copyWith(color: color),
        ),
      ],
    );
  }
}
