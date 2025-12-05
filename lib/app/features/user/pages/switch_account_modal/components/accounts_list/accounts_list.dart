// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/components/accounts_list/account_tile.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/switch_account_modal_provider.r.dart';

class SwitchAccountModalList extends ConsumerWidget {
  const SwitchAccountModalList({
    required this.onSelectUser,
    required this.enableAccountManagement,
    super.key,
  });

  final VoidCallback onSelectUser;
  final bool enableAccountManagement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalStateAsync = ref.watch(switchAccountModalNotifierProvider);

    return modalStateAsync.when(
      data: (modalState) {
        if (modalState.identityKeyNames.isEmpty) {
          return const SizedBox.shrink();
        }

        return SeparatedColumn(
          separator: SizedBox(height: 16.0.s),
          children: modalState.identityKeyNames
              .map(
                (identityKeyName) => SwitchAccountModalTile(
                  identityKeyName: identityKeyName,
                  isCurrentUser: enableAccountManagement &&
                      identityKeyName == modalState.currentIdentityKeyName,
                  onSelectUser: onSelectUser,
                ),
              )
              .toList(),
        );
      },
      loading: () => const _Skeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

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
