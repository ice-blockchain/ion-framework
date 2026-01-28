// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/messages_context_menu/one_to_one_messages_context_menu.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class OneToOneMessagingHeader extends ConsumerWidget {
  const OneToOneMessagingHeader({
    required this.conversationId,
    required this.receiverMasterPubkey,
    super.key,
  });

  final String conversationId;
  final String receiverMasterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked =
        ref.watch(isBlockedNotifierProvider(receiverMasterPubkey)).valueOrNull ?? true;
    final isBlockedBy =
        ref.watch(isBlockedByNotifierProvider(receiverMasterPubkey)).valueOrNull ?? true;
    final isVerified = ref.watch(isUserVerifiedProvider(receiverMasterPubkey));
    final isNicknameProven = ref.watch(isNicknameProvenProvider(receiverMasterPubkey));

    final userPreviewData = ref.watch(userPreviewDataProvider(receiverMasterPubkey));
    // Show skeleton while loading user data (unless deleted)
    if (userPreviewData.isLoading && !userPreviewData.hasValue) {
      return const _HeaderSkeleton();
    }

    final metadata = userPreviewData.valueOrNull;

    final receiverPicture = metadata != null && !isBlockedBy && metadata.data.avatarUrl != null
        ? metadata.data.avatarUrl
        : Assets.svg.iconProfileNoimage;
    final receiverName = metadata?.data.name;
    final receiverDisplayName = metadata?.data.trimmedDisplayName;

    final subtitle = Text(
      withPrefix(
        input: receiverName,
        textDirection: Directionality.of(context),
      ),
      style: context.theme.appTextThemes.caption.copyWith(
        color: context.theme.appColors.quaternaryText,
      ),
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0.s, 8.0.s, 16.0.s, 12.0.s),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Assets.svg.iconChatBack.icon(
              size: 24.0.s,
              flipForRtl: true,
            ),
          ),
          SizedBox(width: 12.0.s),
          Expanded(
            child: GestureDetector(
              onTap: () => ProfileRoute(pubkey: receiverMasterPubkey).push<void>(context),
              child: Row(
                children: [
                  if (isBlockedBy)
                    Avatar(size: 36.0.s)
                  else
                    StoryColoredProfileAvatar(
                      pubkey: receiverMasterPubkey,
                      size: 36.0.s,
                      useRandomGradient: true,
                      imageUrl: receiverPicture,
                    ),
                  SizedBox(width: 10.0.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                metadata == null
                                    ? context.i18n.common_deleted_account
                                    : receiverDisplayName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.theme.appTextThemes.subtitle3,
                              ),
                            ),
                            if (isVerified) ...[
                              SizedBox(width: 3.0.s),
                              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
                            ],
                          ],
                        ),
                        SizedBox(height: 1.0.s),
                        if (isNicknameProven)
                          subtitle
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              subtitle,
                              SizedBox(width: 4.0.s),
                              Text(context.i18n.nickname_not_owned_suffix),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          OneToOneMessagingContextMenu(
            isBlocked: isBlocked,
            onToggleMute: () async {
              final mutedConversationService =
                  await ref.read(muteConversationServiceProvider.future);

              await mutedConversationService.toggleMutedConversation(receiverMasterPubkey);
            },
            conversationId: conversationId,
            receiverMasterPubkey: receiverMasterPubkey,
          ),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0.s, 8.0.s, 16.0.s, 12.0.s),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Assets.svg.iconChatBack.icon(
              size: 24.0.s,
              flipForRtl: true,
            ),
          ),
          SizedBox(width: 12.0.s),
          ContainerSkeleton(
            height: 36.0.s,
            width: 36.0.s,
          ),
          SizedBox(width: 10.0.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerSkeleton(
                  height: context.theme.appTextThemes.subtitle3.fontSize!.s,
                  width: 120.0.s,
                  skeletonBaseColor: context.theme.appColors.onTertiaryFill,
                ),
                SizedBox(height: 4.0.s),
                ContainerSkeleton(
                  height: context.theme.appTextThemes.subtitle3.fontSize!.s,
                  width: 150.0.s,
                  skeletonBaseColor: context.theme.appColors.onTertiaryFill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
