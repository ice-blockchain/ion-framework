// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';

class CurrentUserAvatar extends ConsumerWidget {
  const CurrentUserAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    return currentPubkey != null
        ? IonConnectAvatar(size: 30.0.s, masterPubkey: currentPubkey)
        : const SizedBox.shrink();
  }
}
