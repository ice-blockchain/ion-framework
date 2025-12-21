// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/providers/creator_tokens_filter_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/filter/token_type_filter_menu.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenTypeFilterDropdown extends HookWidget {
  const TokenTypeFilterDropdown({
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
      child: _DropdownButton(opened: opened.value),
    );
  }
}

class _DropdownButton extends ConsumerWidget {
  const _DropdownButton({required this.opened});

  final bool opened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(creatorTokensFilterNotifierProvider);
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedFilter.getLabel(context),
          style: textStyles.subtitle3.copyWith(
            color: colors.onTertiaryBackground,
          ),
        ),
        SizedBox(width: 4.0.s),
        (opened ? Assets.svg.iconArrowUp : Assets.svg.iconArrowDown).icon(
          color: colors.onTertiaryBackground,
          size: 12.0.s,
        ),
      ],
    );
  }
}
