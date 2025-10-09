// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/conversation_edit_bottom_bar/conversation_edit_bottom_bar.dart';
import 'package:ion/app/features/chat/views/components/unread_messages_counter.dart';
import 'package:ion/app/features/wallets/views/components/unseen_transactions_counter.dart';
import 'package:ion/app/router/main_tabs/components/components.dart';
import 'package:ion/app/utils/main_tab.dart';

const _navBarVerticalPadding = 9.0;

class MainTabNavigation extends HookWidget {
  const MainTabNavigation({
    required this.shell,
    required this.state,
    super.key,
  });

  final StatefulNavigationShell shell;
  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    final tabHistory = useState<List<int>>([shell.currentIndex]);
    final tabPressStreamController = useStreamController<TabPressSteamData>();
    final currentTab = TabItem.fromNavigationIndex(shell.currentIndex);
    final canPop = useState<bool>(GoRouter.of(context).canPop());

    // GoRouter.of(context).canPop() holds incorrect value during build phase
    // so we need to wait for it to finish in order to get the correct value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      canPop.value = GoRouter.of(context).canPop();
    });

    return PopScope(
      canPop: !canPop.value && (tabHistory.value.length <= 1 || currentTab == TabItem.feed),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            if (tabHistory.value.length > 1) {
              tabHistory.value = List.from(tabHistory.value)..removeLast();
              final previousIndex = tabHistory.value.last;
              shell.goBranch(previousIndex);
            }
          }
        }
      },
      child: Scaffold(
        body: MainTabNavigationContainer(
          tabPressStream: tabPressStreamController.stream,
          child: shell,
        ),
        bottomNavigationBar: state.shouldHideBottomBar
            ? null
            : _BottomNavBarContent(
                state: state,
                currentTab: currentTab,
                onTabPressed: (TabItem tabItem) {
                  final newIndex = tabItem.navigationIndex;
                  if (tabHistory.value.last != newIndex) {
                    tabHistory.value = List.from(tabHistory.value)..add(newIndex);
                  }

                  tabPressStreamController.add((current: currentTab, pressed: tabItem));
                  if (tabItem == TabItem.main) {
                    _handleMainButtonTap(context, currentTab);
                  } else {
                    _navigateToTab(context, tabItem, initialLocation: currentTab == tabItem);
                  }
                },
              ),
      ),
    );
  }

  void _handleMainButtonTap(BuildContext context, TabItem currentTab) {
    HapticFeedback.mediumImpact();

    if (state.isMainModalOpen) {
      context.pop();
    } else {
      context.push(currentTab.mainModalLocation);
    }
  }

  void _navigateToTab(BuildContext context, TabItem tabItem, {required bool initialLocation}) {
    if (state.isMainModalOpen) {
      context.pop();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => shell.goBranch(tabItem.navigationIndex),
      );
    } else {
      shell.goBranch(tabItem.navigationIndex, initialLocation: initialLocation);
    }
  }
}

class _BottomNavBarContent extends ConsumerWidget {
  const _BottomNavBarContent({
    required this.state,
    required this.currentTab,
    required this.onTabPressed,
  });

  final GoRouterState state;
  final TabItem currentTab;
  final ValueChanged<TabItem> onTabPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsEditMode = ref.watch(conversationsEditModeProvider);
    final bottomPadding = getBottomPadding(context, navBarVerticalPadding: _navBarVerticalPadding);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.theme.appColors.secondaryBackground,
            boxShadow: state.isMainModalOpen
                ? null
                : [
                    BoxShadow(
                      color: context.theme.appColors.darkBlue.withAlpha(14),
                      blurRadius: 10,
                    ),
                  ],
          ),
          padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: TabItem.values.map((tabItem) {
              final isSelected = currentTab == tabItem;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTabPressed(tabItem),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: _navBarVerticalPadding.s),
                    color: context.theme.appColors.secondaryBackground,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        tabItem.getIcon(isSelected: isSelected),
                        if (tabItem == TabItem.chat) const UnreadMessagesCounter(),
                        if (tabItem == TabItem.wallet) const UnseenTransactionsCounter(),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (conversationsEditMode && currentTab == TabItem.chat) const ConversationEditBottomBar(),
      ],
    );
  }
}
