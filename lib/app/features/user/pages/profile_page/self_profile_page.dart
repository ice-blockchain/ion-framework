// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_page.dart';

class SelfProfilePage extends ConsumerWidget {
  const SelfProfilePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentPubkey == null) {
      return const SizedBox.shrink();
    }

    return ProfilePage(
      masterPubkey: currentPubkey,
      showBackButton: false,
    );
  }
}
