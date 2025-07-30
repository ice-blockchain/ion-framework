// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class FeedNavigation extends StatelessWidget {
  const FeedNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FeedSimpleSearchRoute().push<void>(context),
            child: const IgnorePointer(child: SearchInput()),
          ),
        ),
      ],
    );
  }
}
