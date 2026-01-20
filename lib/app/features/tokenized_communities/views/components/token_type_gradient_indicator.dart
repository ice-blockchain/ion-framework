// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/token_type_gradients.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

/// A widget that displays a gradient circle indicator for token types.
///
/// Shows a colored gradient circle for content token types (post, video, article).
/// Returns an empty widget for profile tokens or if no gradient is available.
class TokenTypeGradientIndicator extends StatelessWidget {
  const TokenTypeGradientIndicator({
    required this.tokenType,
    super.key,
  });

  final CommunityTokenType tokenType;

  @override
  Widget build(BuildContext context) {
    final gradient = TokenTypeGradients.getGradientForType(tokenType);
    if (gradient == null) return const SizedBox.shrink();

    return Container(
      width: 12.0.s,
      height: 12.0.s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
}
