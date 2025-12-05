// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/image/blurhash_image_wrapper.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/utils/url.dart';

// Setting SizedBox.shrink placeholder to avoid default while screen placeholder that brings flickering
const _placeholder = SizedBox.shrink();

class VideoThumbnailPreview extends ConsumerWidget {
  const VideoThumbnailPreview({
    required this.thumbnailUrl,
    required this.aspectRatio,
    this.blurhash,
    this.authorPubkey,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String? thumbnailUrl;
  final String? blurhash;
  final String? authorPubkey;
  final BoxFit fit;
  final double aspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no thumbnail URL, show loading indicator
    if (thumbnailUrl case final thumbnailUrl? when thumbnailUrl.isNotEmpty) {
      // Wrap thumbnail with BlurHash background if available
      return BlurhashImageWrapper(
        blurhash: blurhash,
        aspectRatio: aspectRatio,
        child: (isNetworkUrl(thumbnailUrl))
            ? IonConnectNetworkImage(
                imageUrl: thumbnailUrl,
                authorPubkey: authorPubkey ?? '',
                fit: fit,
                placeholder: (_, __) => _placeholder,
              )
            : Image.file(
                File(thumbnailUrl),
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _placeholder,
              ),
      );
    }

    return CenteredLoadingIndicator(size: Size.square(30.s));
  }
}
