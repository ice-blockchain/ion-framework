// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/user_pinned_content_provider.m.dart';
import 'package:ion/generated/assets.gen.dart';

class PinnedContentHeader extends ConsumerWidget {
  const PinnedContentHeader({required this.eventReference, super.key});

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));
    if (!isOwnedByCurrentUser) {
      return const SizedBox.shrink();
    }

    final pinnedState = ref.watch(togglePinnedNotifierProvider(eventReference: eventReference));
    final isPinned = pinnedState.value ?? false;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isPinned
          ? Padding(
              padding: EdgeInsetsDirectional.only(start: 16.0.s, top: 12.0.s),
              child: Row(
                children: [
                  Assets.svg.iconChatPin.icon(
                    size: 16.0.s,
                    color: context.theme.appColors.onTertiaryBackground,
                  ),
                  SizedBox(width: 4.0.s),
                  Flexible(
                    child: Text(
                      context.i18n.pinned_item,
                      style: context.theme.appTextThemes.body2.copyWith(
                        color: context.theme.appColors.onTertiaryBackground,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
