// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_button/navigation_button.dart';
import 'package:ion/generated/assets.gen.dart';

class CommunityTokensButton extends StatelessWidget {
  const CommunityTokensButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationButton(
      onPressed: () => CreatorTokensRoute().push<void>(context),
      icon: Assets.svg.fluentFood24Regular.icon(size: NavigationButton.defaultSize),
    );
  }
}
