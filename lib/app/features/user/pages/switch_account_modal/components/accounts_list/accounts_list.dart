// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/components/accounts_list/account_tile.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/switch_account_modal_provider.r.dart';

class AccountsList extends ConsumerWidget {
  const AccountsList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalStateAsync = ref.watch(switchAccountModalNotifierProvider);

    return modalStateAsync.when(
      data: (modalState) {
        if (modalState.accounts.isEmpty) {
          return const SizedBox.shrink();
        }

        return SeparatedColumn(
          separator: SizedBox(height: 16.0.s),
          children: modalState.accounts
              .map(
                (account) => AccountsTile(
                  identityKeyName: account.identityKeyName,
                  accountInfo: account.accountInfo,
                  isCurrentUser: account.isCurrentUser,
                ),
              )
              .toList(),
        );
      },
      loading: () => const _AccountsListSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AccountsListSkeleton extends StatelessWidget {
  const _AccountsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separator: SizedBox(height: 16.0.s),
      children: [
        Skeleton(
          child: ListItem(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s),
            backgroundColor: context.theme.appColors.tertiaryBackground,
            borderRadius: ListItem.defaultBorderRadius,
            constraints: ListItem.defaultConstraints,
          ),
        ),
      ],
    );
  }
}
