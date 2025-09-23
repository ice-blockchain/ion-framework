// SPDX-License-Identifier: ice License 1.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/utils/image_path.dart';

/// Custom hook for pre-caching images (both SVG and regular formats)
({bool isContentReady}) usePrecacheImage(
  String imageUrl,
  BuildContext context, [
  List<Object?>? keys,
]) {
  final showContent = useState(false);

  useEffect(
    () {
      if (imageUrl.isEmpty) {
        showContent.value = true;
        return null;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
          final precacheFuture = imageUrl.isSvg
              ? () async {
                  final loader = SvgNetworkLoader(imageUrl);
                  await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
                }()
              : precacheImage(CachedNetworkImageProvider(imageUrl), context);

          await precacheFuture.whenComplete(() {
            if (context.mounted) {
              showContent.value = true;
            }
          });
        } else {
          showContent.value = true;
        }
      });

      return null;
    },
    keys,
  );

  return (isContentReady: showContent.value);
}
