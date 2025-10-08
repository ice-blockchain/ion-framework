// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/providers/community_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/unread_message_count_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/archived_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_skeleton/recent_chat_skeleton.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/archive_chat_tile.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_tile.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/collapsing_app_bar.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/generated/assets.gen.dart';

class RecentChatsTimelinePage extends HookConsumerWidget {
  const RecentChatsTimelinePage({
    required this.conversations,
    required this.scrollController,
    super.key,
  });

  final List<ConversationListItem> conversations;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveVisible = useState(false);
    final isOverscrolling = useState(false);

    useScrollTopOnTabPress(context, scrollController: scrollController);
    final archivedConversations = ref.watch(archivedConversationsProvider);
    final isArchivedConversationsEmpty = archivedConversations.valueOrNull?.isEmpty ?? true;

    useEffect(
      () {
        if (Platform.isIOS) {
          void listener() {
            if (scrollController.position.userScrollDirection == ScrollDirection.forward &&
                scrollController.offset < -60.0.s) {
              archiveVisible.value = true;
            } else if (scrollController.position.userScrollDirection == ScrollDirection.reverse &&
                scrollController.offset > 30.0.s) {
              archiveVisible.value = false;
            }
          }

          scrollController.addListener(listener);

          return () => scrollController.removeListener(listener);
        }

        return null;
      },
      const [],
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (Platform.isAndroid) {
          // Only process if we have archived conversations
          if (isArchivedConversationsEmpty) return false;

          if (notification is ScrollStartNotification) {
            // Reset overscroll state when starting a new scroll
            isOverscrolling.value = false;
          } else if (notification is OverscrollNotification) {
            // User is overscrolling at the top
            if (notification.overscroll < 0) {
              isOverscrolling.value = true;
              archiveVisible.value = true;
            }
          } else if (notification is ScrollUpdateNotification) {
            // Hide archive when scrolling down in normal content
            if (notification.scrollDelta != null &&
                notification.scrollDelta! > 0 &&
                !isOverscrolling.value) {
              archiveVisible.value = false;
            }
          } else if (notification is ScrollEndNotification) {
            // If we end scroll and we're not overscrolling, hide archive
            if (!isOverscrolling.value || (notification.metrics.pixels > 0)) {
              archiveVisible.value = false;
            }
          }
        }

        return false;
      },
      child: PullToRefreshBuilder(
        sliverAppBar: CollapsingAppBar(
          height: SearchInput.height,
          topOffset: 0,
          bottomOffset: 0,
          child: FlexibleSpaceBar(
            background: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ChatQuickSearchRoute().push<void>(context),
              child: const IgnorePointer(
                child: SearchInput(),
              ),
            ),
          ),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: 12.0.s),
              child: const HorizontalSeparator(),
            ),
          ),
          if (scrollController.hasClients && !isArchivedConversationsEmpty)
            SliverToBoxAdapter(
              child: AnimatedOpacity(
                opacity: archiveVisible.value ? 1.0 : 0.0,
                duration: 500.milliseconds,
                child: archiveVisible.value ? const ArchiveChatTile() : const SizedBox.shrink(),
              ),
            ),
          if (!isArchivedConversationsEmpty && conversations.isNotEmpty)
            const SliverToBoxAdapter(
              child: HorizontalSeparator(),
            ),
          ConversationList(conversations: conversations.where((c) => !c.isArchived).toList()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: 12.0.s),
              child: const HorizontalSeparator(),
            ),
          ),
        ],
        onRefresh: () async {
          await _forceSyncUserMetadata(ref);
        },
        builder: (context, slivers) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: scrollController,
          slivers: slivers,
        ),
      ),
    );
  }

  Future<void> _forceSyncUserMetadata(WidgetRef ref) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentUserMasterPubkey == null) return;

    final participantsMasterPubkeys = conversations
        .where((c) => c.type == ConversationType.oneToOne)
        .map((c) => c.receiverMasterPubkey(currentUserMasterPubkey))
        .toSet()
        .nonNulls;

    if (participantsMasterPubkeys.isEmpty) return;

    for (final masterPubkey in participantsMasterPubkeys) {
      ref.read(userMetadataProvider(masterPubkey, cache: false));
    }
  }
}

class ConversationList extends ConsumerWidget {
  const ConversationList({required this.conversations, super.key});

  final List<ConversationListItem> conversations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverFixedExtentList(
      itemExtent: 73.5.s, // Fixed height for all chat tiles matching skeleton tiles
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final conversation = conversations[index];
          return Column(
            children: [
              if (conversation.type == ConversationType.community)
                CommunityRecentChatTile(
                  conversation: conversation,
                  key: ValueKey(conversation.conversationId),
                )
              else if (conversation.type == ConversationType.oneToOne)
                E2eeRecentChatTile(
                  conversation: conversation,
                  key: ValueKey(conversation.conversationId),
                )
              else if (conversation.type == ConversationType.group)
                EncryptedGroupRecentChatTile(
                  conversation: conversation,
                  key: ValueKey(conversation.conversationId),
                ),
              const HorizontalSeparator(), // Add separator after each item
            ],
          );
        },
        childCount: conversations.length,
      ),
    );
  }
}

class CommunityRecentChatTile extends ConsumerWidget {
  const CommunityRecentChatTile({required this.conversation, super.key});

  final ConversationListItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityMetadataProvider(conversation.conversationId)).valueOrNull;

    final unreadMessagesCount =
        ref.watch(getUnreadMessagesCountProvider(conversation.conversationId));
    if (community == null) {
      return const SizedBox.shrink();
    }

    final eventReference = ReplaceablePrivateDirectMessageEntity.fromEventMessage(
      conversation.latestMessage!,
    ).toEventReference();

    final entity =
        ReplaceablePrivateDirectMessageData.fromEventMessage(conversation.latestMessage!);

    return RecentChatTile(
      name: community.data.name,
      conversation: conversation,
      avatarUrl: community.data.avatar?.url,
      eventReference: eventReference,
      defaultAvatar: Container(
        width: 40.0.s,
        height: 40.0.s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.theme.appColors.onTertiaryFill,
          borderRadius: BorderRadius.circular(12.0.s),
        ),
        child: Assets.svg.iconChannelEmptychannel.icon(
          size: 26.0.s,
          color: context.theme.appColors.secondaryBackground,
        ),
      ),
      unreadMessagesCount: unreadMessagesCount.valueOrNull ?? 0,
      lastMessageAt: (conversation.latestMessage?.createdAt ?? conversation.joinedAt).toDateTime,
      lastMessageContent: conversation.latestMessage?.content ?? context.i18n.empty_message_history,
      messageType: entity.messageType,
      onTap: () {
        ConversationRoute(conversationId: conversation.conversationId).push<void>(context);
      },
    );
  }
}

class E2eeRecentChatTile extends HookConsumerWidget {
  const E2eeRecentChatTile({required this.conversation, super.key});

  final ConversationListItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversation.latestMessage == null) {
      return const SizedBox.shrink();
    }

    final entity =
        ReplaceablePrivateDirectMessageData.fromEventMessage(conversation.latestMessage!);

    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);

    final receiverMasterPubkey =
        entity.relatedPubkeys?.firstWhereOrNull((p) => p.value != currentUserPubkey)?.value;

    if (receiverMasterPubkey == null) {
      return const SizedBox.shrink();
    }

    final unreadMessagesCount =
        ref.watch(getUnreadMessagesCountProvider(conversation.conversationId));

    final eventReference = ReplaceablePrivateDirectMessageEntity.fromEventMessage(
      conversation.latestMessage!,
    ).toEventReference();

    final isUserVerified = ref.watch(isUserVerifiedProvider(receiverMasterPubkey));

    final userMetadata = ref.watch(userMetadataProvider(receiverMasterPubkey));

    if (userMetadata.isLoading) {
      return const RecentChatSkeletonItem();
    }

    final metadata = userMetadata.valueOrNull;

    return RecentChatTile(
      defaultAvatar: null,
      conversation: conversation,
      messageType: entity.messageType,
      name: metadata.isDeleted ? context.i18n.common_deleted_account : metadata!.data.displayName,
      avatarUrl: metadata.isDeleted ? Assets.svg.iconProfileNoimage : metadata!.data.avatarUrl,
      eventReference: eventReference,
      unreadMessagesCount: unreadMessagesCount.valueOrNull ?? 0,
      lastMessageContent: entity.messageType == MessageType.document
          ? entity.primaryMedia?.alt ?? ''
          : entity.content,
      lastMessageAt: (conversation.latestMessage?.createdAt ?? conversation.joinedAt).toDateTime,
      isVerified: isUserVerified,
      onTap: () {
        ConversationRoute(receiverMasterPubkey: receiverMasterPubkey).push<void>(context);
      },
    );
  }
}

class EncryptedGroupRecentChatTile extends HookConsumerWidget {
  const EncryptedGroupRecentChatTile({required this.conversation, super.key});

  final ConversationListItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ConversationListItem(:latestMessage) = conversation;

    if (latestMessage == null) {
      return const SizedBox.shrink();
    }

    final entity = ReplaceablePrivateDirectMessageData.fromEventMessage(latestMessage);

    final name = entity.groupSubject?.value ?? '';

    final unreadMessagesCount =
        ref.watch(getUnreadMessagesCountProvider(conversation.conversationId));

    final groupImageFile = useFuture(
      ref.watch(mediaEncryptionServiceProvider).retrieveEncryptedMedia(
            entity.primaryMedia!,
            authorPubkey: latestMessage.masterPubkey,
          ),
    ).data;

    final eventReference = ReplaceablePrivateDirectMessageEntity.fromEventMessage(
      conversation.latestMessage!,
    ).toEventReference();

    return RecentChatTile(
      name: name,
      conversation: conversation,
      eventReference: eventReference,
      avatarWidget: groupImageFile != null ? Image.file(groupImageFile) : null,
      defaultAvatar: Assets.svg.iconChannelEmptychannel.icon(size: 40.0.s),
      lastMessageAt: (conversation.latestMessage?.createdAt ?? conversation.joinedAt).toDateTime,
      lastMessageContent:
          entity.content.isEmpty ? context.i18n.empty_message_history : entity.content,
      unreadMessagesCount: unreadMessagesCount.valueOrNull ?? 0,
      messageType: entity.messageType,
      onTap: () {
        ConversationRoute(conversationId: conversation.conversationId).push<void>(context);
      },
    );
  }
}
