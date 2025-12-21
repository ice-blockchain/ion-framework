// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/providers/creator_tokens_filter_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/filter/token_type_filter_menu.dart';

class TokenTypeFilterButton extends HookWidget {
  const TokenTypeFilterButton({
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final opened = useState(false);

    return OverlayMenu(
      scrollController: scrollController,
      onOpen: () => opened.value = true,
      onClose: () => opened.value = false,
      menuBuilder: (closeMenu) => TokenTypeFilterMenu(closeMenu: closeMenu),
      child: _FilterButton(
        opened: opened.value,
        onPressed: () {
          opened.value = !opened.value;
        },
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton({
    required this.opened,
    required this.onPressed,
  });

  final bool opened;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(creatorTokensFilterNotifierProvider);
    final colors = context.theme.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 4.0.s,
        horizontal: 8.0.s,
      ),
      child: Button.dropdown(
        onPressed: onPressed,
        useDefaultBorderRadius: true,
        useDefaultPaddings: true,
        backgroundColor: colors.secondaryBackground,
        borderColor: colors.strokeElements,
        label: Text(
          selectedFilter.getLabel(context),
          style: context.theme.appTextThemes.subtitle3,
        ),
        opened: opened,
      ),
    );
  }
}
