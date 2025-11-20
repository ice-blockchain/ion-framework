// SPDX-License-Identifier: ice License 1.0

// lib/app/features/auth/views/pages/switch_user_loader_page/switch_user_loader_page.dart
import 'package:flutter/material.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';

class SwitchUserLoaderPage extends StatelessWidget {
  const SwitchUserLoaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: Center(
        child: IONLoadingIndicatorThemed(size: Size.square(48.s)),
      ),
    );
  }
}
