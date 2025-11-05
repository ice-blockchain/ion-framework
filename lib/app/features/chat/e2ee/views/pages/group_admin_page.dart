// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/model/group_admin_tab.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/update_group_chat_members_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/add_members_button.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_avatar.dart'
    show GroupAvatar;
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_context_menu.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_details.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_tabs_header/group_tabs_header.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/componentes/group_participant_list_item.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupAdminPage extends HookConsumerWidget {
  const GroupAdminPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  double get paddingTop => 60.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;

    if (groupMetadata == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final groupName = groupMetadata.name;
    final memberCount = groupMetadata.members.length;

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserRole = currentUserMasterPubkey != null
        ? groupMetadata.currentUserRole(currentUserMasterPubkey)
        : null;

    final scrollController = useScrollController();
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: paddingTop);
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final backgroundColor = context.theme.appColors.secondaryBackground;

    final menuCloseSignal = useMemoized(OverlayMenuCloseSignal.new);
    useEffect(() => menuCloseSignal.dispose, [menuCloseSignal]);

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              child: DefaultTabController(
                length: GroupAdminTab.values.length,
                child: NestedScrollView(
                  controller: scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 12.0.s),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GroupAvatar(
                                  avatar: groupMetadata.avatar,
                                ),
                              ],
                            ),
                            SizedBox(height: 16.0.s),
                            GroupDetails(
                              conversationId: conversationId,
                              groupName: groupName,
                              memberCount: memberCount,
                              currentUserRole: currentUserRole,
                            ),
                            SizedBox(height: 24.0.s),
                          ],
                        ),
                      ),
                      PinnedHeaderSliver(
                        child: ColoredBox(
                          color: backgroundColor,
                          child: const GroupTabsHeader(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SectionSeparator()),
                    ];
                  },
                  body: TabBarView(
                    children: GroupAdminTab.values.map((tab) {
                      return _GroupTabContent(
                        tab: tab,
                        conversationId: conversationId,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            _IgnorePointerWrapper(
              shouldWrap: opacity <= 0.5,
              child: Opacity(
                opacity: opacity,
                child: NavigationAppBar(
                  useScreenTopOffset: true,
                  backButtonIcon: backButtonIcon,
                  scrollController: scrollController,
                  horizontalPadding: 0,
                  title: _GroupHeader(
                    opacity: opacity,
                    groupName: groupName,
                    memberCount: memberCount,
                    avatar: groupMetadata.avatar,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: statusBarHeight,
              start: 0,
              child: NavigationBackButton(
                context.pop,
                icon: backButtonIcon,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 16.s, top: statusBarHeight),
                child: SizedBox(
                  height: NavigationAppBar.screenHeaderHeight,
                  child: GroupContextMenu(
                    conversationId: conversationId,
                    closeSignal: menuCloseSignal,
                    currentUserRole: currentUserRole,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.opacity,
    required this.groupName,
    required this.memberCount,
    required this.avatar,
  });

  final double opacity;
  final String groupName;
  final int memberCount;
  final ({String masterPubkey, MediaAttachment? media}) avatar;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GroupAvatar(
            avatar: avatar,
            size: 36.0.s,
            borderRadius: BorderRadius.circular(10.0.s),
          ),
          SizedBox(width: 10.0.s),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: context.theme.appTextThemes.title,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.0.s),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Assets.svg.iconChannelMembers.icon(
                      size: 10.0.s,
                      color: context.theme.appColors.quaternaryText,
                    ),
                    SizedBox(width: 3.0.s),
                    Text(
                      memberCount.toString(),
                      style: context.theme.appTextThemes.caption.copyWith(
                        color: context.theme.appColors.quaternaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTabContent extends ConsumerWidget {
  const _GroupTabContent({
    required this.tab,
    required this.conversationId,
  });

  final GroupAdminTab tab;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab == GroupAdminTab.members) {
      return _GroupMembersTab(conversationId: conversationId);
    }

    return Center(
      child: Text(
        context.i18n.group_tab_coming_soon(tab.getTitle(context)),
        style: context.theme.appTextThemes.body,
      ),
    );
  }
}

class _GroupMembersTab extends HookConsumerWidget {
  const _GroupMembersTab({
    required this.conversationId,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;

    if (groupMetadata == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final members = groupMetadata.members;

    if (members.isEmpty) {
      return Center(
        child: Text(
          context.i18n.group_no_members,
          style: context.theme.appTextThemes.body,
        ),
      );
    }

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserRole = currentUserMasterPubkey != null
        ? groupMetadata.currentUserRole(currentUserMasterPubkey)
        : null;

    final canRemoveMembers = currentUserRole?.canRemoveMembers ?? false;
    final isOwner = currentUserRole is GroupMemberRoleOwner;

    // Sort members so that owner comes first
    final sortedMembers = [...members]..sort((a, b) {
        final aIsOwner = a is GroupMemberRoleOwner;
        final bIsOwner = b is GroupMemberRoleOwner;
        if (aIsOwner && !bIsOwner) {
          return -1;
        }
        if (!aIsOwner && bIsOwner) {
          return 1;
        }
        return 0;
      });

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.0.s, horizontal: 16.0.s),
      itemCount: sortedMembers.length + (isOwner ? 1 : 0),
      separatorBuilder: (_, int index) {
        return SizedBox(height: 12.0.s);
      },
      itemBuilder: (_, int i) {
        // Show AddMembersButton first if user is owner
        if (isOwner && i == 0) {
          return Padding(
            padding: EdgeInsetsGeometry.only(
              top: 10.0.s,
            ),
            child: AddMembersButton(
              onTap: () {
                AddGroupParticipantsModalRoute(conversationId: conversationId).push<void>(context);
              },
            ),
          );
        }

        // Adjust index for member items when AddMembersButton is present
        final memberIndex = isOwner ? i - 1 : i;
        final memberRole = sortedMembers[memberIndex];
        final participantMasterkey = memberRole.masterPubkey;

        return GroupParticipantsListItem(
          participantMasterkey: participantMasterkey,
          role: memberRole,
          showRemoveButton: canRemoveMembers,
          onRemove: () {
            ref.read(updateGroupChatMembersServiceProvider).removeMembers(
              groupId: conversationId,
              participantMasterPubkeys: [participantMasterkey],
            );
          },
          onTap: () {
            ProfileRoute(pubkey: participantMasterkey).push<void>(context);
          },
        );
      },
    );
  }
}

class _IgnorePointerWrapper extends StatelessWidget {
  const _IgnorePointerWrapper({required this.child, required this.shouldWrap});

  final Widget child;
  final bool shouldWrap;

  @override
  Widget build(BuildContext context) {
    return shouldWrap ? IgnorePointer(child: child) : child;
  }
}
