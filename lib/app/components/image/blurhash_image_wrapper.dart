// SPDX-License-Identifier: ice License 1.0

import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that displays a BlurHash placeholder behind a child widget.
/// Useful for images that load progressively or need a blurred preview.
class BlurhashImageWrapper extends StatelessWidget {
  const BlurhashImageWrapper({
    required this.child,
    required this.aspectRatio,
    this.blurhash,
    super.key,
  });

  /// The content to display on top of the BlurHash
  final Widget child;

  /// Aspect ratio for the BlurHash background.
  final double aspectRatio;

  /// The BlurHash string. If null, only the child is displayed.
  final String? blurhash;

  @override
  Widget build(BuildContext context) {
    if (blurhash case final blurhash? when blurhash.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: BlurhashFfi(hash: blurhash),
            ),
          ),
          child,
        ],
      );
    }

    // If no blurhash, show thumbnail directly
    return child;
  }
}
