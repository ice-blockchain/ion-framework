// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/channel/hooks/use_can_post_to_channel.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/channel_page/components/empty_state_copy_link.dart';
import 'package:ion/app/features/chat/community/models/community_join_requests_state.f.dart';
import 'package:ion/app/features/chat/community/providers/community_join_requests_provider.r.dart';
import 'package:ion/app/features/chat/community/providers/community_metadata_provider.r.dart';
import 'package:ion/app/features/chat/community/providers/join_community_provider.r.dart';
import 'package:ion/app/features/chat/community/view/components/community_member_count_tile.dart';
import 'package:ion/app/features/chat/components/messaging_header/messaging_header.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_input_bar.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class ChannelMessagingPage extends HookConsumerWidget {
  const ChannelMessagingPage({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(communityMetadataProvider(communityId)).valueOrNull;
    final joinRequests = ref.watch(communityJoinRequestsProvider).valueOrNull;
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    final isJoined = useMemoized(
        () =>
            joinRequests?.accepted.any((community) => community.data.uuid == communityId) ?? false,
        [
          joinRequests,
          communityId,
        ]);

    final messages = ref.watch(conversationMessagesProvider(communityId));

    final canPost = useCanPostToChannel(channel: channel, currentPubkey: currentPubkey);

    if (channel == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            MessagingHeader(
              onTap: () => ChannelDetailRoute(uuid: communityId).push<void>(context),
              imageWidget:
                  channel.data.avatar?.url != null ? Image.network(channel.data.avatar!.url) : null,
              name: channel.data.name,
              subtitle: CommunityMemberCountTile(
                community: channel,
              ),
              conversationId: '', //TODO: set when channels are impl
            ),
            Expanded(
              child: messages.maybeWhen(
                data: (messages) {
                  if (messages.isEmpty) {
                    return MessagingEmptyView(
                      title: context.i18n.common_invitation_link,
                      asset: Assets.svg.iconChatEmptystate,
                      trailing: EmptyStateCopyLink(link: channel.data.defaultInvitationLink),
                      leading: Column(
                        children: [
                          SizedBox(height: 12.0.s),
                          Text(
                            context.i18n.channel_created_message,
                            style: context.theme.appTextThemes.caption2.copyWith(
                              color: context.theme.appColors.tertiaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return ColoredBox(
                      color: context.theme.appColors.primaryBackground,
                      child: const SizedBox.expand(),
                    );
                  }
                },
                orElse: () => ColoredBox(
                  color: context.theme.appColors.primaryBackground,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            _ActionButton(
              joinRequests: joinRequests,
              isJoined: isJoined,
              canPost: canPost,
              communityId: communityId,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends HookConsumerWidget {
  const _ActionButton({
    required this.joinRequests,
    required this.isJoined,
    required this.canPost,
    required this.communityId,
  });

  final CommunityJoinRequestsState? joinRequests;
  final bool isJoined;
  final bool canPost;
  final String communityId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (joinRequests == null) {
      return const SizedBox.shrink();
    }

    if (!isJoined) {
      return _JoinButton(
        communityId: communityId,
      );
    }

    if (canPost) {
      return ChatInputBar(
        receiverMasterPubkey: '', //TODO: set when channels are impl
        onSubmitted: ({content, mediaFiles}) async {
          await ref.read(createPostNotifierProvider(CreatePostOption.community).notifier).create(
                content: content != null ? (Delta()..insert('$content\n')) : null,
                communityId: communityId,
              );
        },
        conversationId: communityId,
      );
    } else {
      return const _UnMuteButton();
    }
  }
}

class _UnMuteButton extends HookConsumerWidget {
  const _UnMuteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenSideOffset.large(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0.s),
        child: Button(
          mainAxisSize: MainAxisSize.max,
          onPressed: () {},
          label: Text(context.i18n.button_unmute),
        ),
      ),
    );
  }
}

class _JoinButton extends HookConsumerWidget {
  const _JoinButton({
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenSideOffset.large(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0.s),
        child: Button(
          mainAxisSize: MainAxisSize.max,
          onPressed: () {
            ref.read(joinCommunityNotifierProvider.notifier).joinCommunity(communityId);
          },
          label: Text(context.i18n.channel_join),
          leadingIcon: Assets.svg.iconMenuLogout.icon(
            color: context.theme.appColors.onPrimaryAccent,
            size: 24.0.s,
          ),
        ),
      ),
    );
  }
}
