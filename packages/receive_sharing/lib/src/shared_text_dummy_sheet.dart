// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

/// TODO(neoptolemus): remove this
/// Presentational dummy sheet that displays shared text.
/// Used by the host app inside a bottom sheet.
class SharedTextDummySheet extends StatelessWidget {
  const SharedTextDummySheet({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Shared text',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SelectableText(text),
        ],
      ),
    );
  }
}
