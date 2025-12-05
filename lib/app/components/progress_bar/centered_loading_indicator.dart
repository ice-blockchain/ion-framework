// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';

class CenteredLoadingIndicator extends StatelessWidget {
  const CenteredLoadingIndicator({
    this.size,
    super.key,
  });

  final Size? size;

  @override
  Widget build(BuildContext context) {
    return Center(child: IONLoadingIndicator(size: size));
  }
}
