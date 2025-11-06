// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

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
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/archived_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/archive_chat_tile.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/collapsing_app_bar.dart';

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
        .where((c) => c.type == ConversationType.directEncrypted)
        .map((c) => c.receiverMasterPubkey(currentUserMasterPubkey))
        .toSet()
        .nonNulls;

    if (participantsMasterPubkeys.isEmpty) return;

    for (final masterPubkey in participantsMasterPubkeys) {
      unawaited(ref.read(userMetadataProvider(masterPubkey, cache: false).future));
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
              if (conversation.type == ConversationType.directEncrypted)
                EncryptedDirectChatTile(
                  conversation: conversation,
                  key: ValueKey(conversation.conversationId),
                )
              else if (conversation.type == ConversationType.groupEncrypted)
                EncryptedGroupChatTile(
                  conversation: conversation,
                  key: ValueKey(conversation.conversationId),
                ),
              if (index < conversations.length - 1)
                const HorizontalSeparator(), // Add separator after each item except the last one
            ],
          );
        },
        childCount: conversations.length,
      ),
    );
  }
}
